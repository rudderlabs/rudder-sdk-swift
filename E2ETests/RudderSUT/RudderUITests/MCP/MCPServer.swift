//
//  MCPServer.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import MCP
import Network
import Foundation

class MCPServer: @unchecked Sendable {
    
    // MARK: - Properties
    
    let interpreter: Interpreter
    private var listener: NWListener?
    private var transport: StatefulHTTPServerTransport?
    private var serverTasks: [Task<Void, Never>] = []
    private let lock = NSLock()
    private let executeQueue = DispatchQueue(label: "com.rudderstack.mcp-execute")
    
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
}

// MARK: - Lifecycle

extension MCPServer {
    
    func start(port: UInt16 = 7777) {
        // Omit OriginValidator — Claude Code's internal MCP client does not send an Origin header.
        let transport = StatefulHTTPServerTransport(
            validationPipeline: StandardValidationPipeline(validators: [
                ContentTypeValidator(),
                ProtocolVersionValidator(),
                SessionValidator(),
            ])
        )
        self.transport = transport
        
        let serverTask = Task { [weak self] in
            guard let self else { return }
            
            let server = Server(
                name: "rudder-scenario-engine",
                version: "1.0",
                capabilities: .init(tools: .init())
            )
            
            await server.withMethodHandler(ListTools.self) { [weak self] _ in
                guard let self else { return ListTools.Result(tools: []) }
                return ListTools.Result(tools: self.toolDefinitions())
            }
            
            await server.withMethodHandler(CallTool.self) { [weak self] params in
                guard let self else {
                    return CallTool.Result(
                        content: [.text(text: "Server deallocated", annotations: nil, _meta: nil)],
                        isError: true
                    )
                }
                return self.handleToolCall(name: params.name, arguments: params.arguments)
            }
            
            try? await server.start(transport: transport)
            await server.waitUntilCompleted()
        }
        lock.withLock { serverTasks.append(serverTask) }
        
        guard let nwPort = NWEndpoint.Port(rawValue: port),
              let listener = try? NWListener(using: .tcp, on: nwPort)
        else {
            print("[MCPServer] Failed to start on port \(port)")
            return
        }
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            let task = Task { await self.serveHTTP(connection: connection) }
            self.lock.withLock { self.serverTasks.append(task) }
        }
        
        listener.start(queue: .global(qos: .userInitiated))
        print("[MCPServer] Listening on port \(port)")
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        transport = nil
        lock.withLock {
            serverTasks.forEach { $0.cancel() }
            serverTasks.removeAll()
        }
    }
}

// MARK: - HTTP Connection Handling

extension MCPServer {
    
    private func serveHTTP(connection: NWConnection) async {
        guard let transport else { return }
        connection.start(queue: .global(qos: .userInitiated))
        do {
            guard let request = try await readHTTPRequest(from: connection) else {
                connection.cancel()
                return
            }
            let response = await transport.handleRequest(request)
            await writeHTTPResponse(response, to: connection)
        } catch {
            connection.cancel()
        }
    }
}

// MARK: - Tool Definitions

extension MCPServer {
    
    private func toolDefinitions() -> [Tool] {
        [
            Tool(name: "rudder.init",
                 description: "Initialize the RudderStack SDK with a write key and data plane URL.",
                 inputSchema: schema(["writeKey": strProp("The SDK write key"),
                                      "dataPlaneUrl": strProp("The data plane URL"),
                                      "options": objProp("Optional SDK configuration flags")])),
            
            Tool(name: "rudder.track",
                 description: "Send a track event to the SDK.",
                 inputSchema: schema(["name": strProp("Event name"),
                                      "properties": objProp("Event properties"),
                                      "options": objProp("RudderOption: integrations, customContext, externalIds")],
                                     required: ["name"])),
            
            Tool(name: "rudder.identify",
                 description: "Identify a user.",
                 inputSchema: schema(["userId": strProp("User ID"),
                                      "traits": objProp("User traits"),
                                      "options": objProp("RudderOption: integrations, customContext, externalIds")])),
            
            Tool(name: "rudder.screen",
                 description: "Send a screen event to the SDK.",
                 inputSchema: schema(["name": strProp("Screen name"),
                                      "category": strProp("Screen category"),
                                      "properties": objProp("Screen properties"),
                                      "options": objProp("RudderOption: integrations, customContext, externalIds")],
                                     required: ["name"])),
            
            Tool(name: "rudder.group",
                 description: "Associate user with a group.",
                 inputSchema: schema(["groupId": strProp("Group ID"),
                                      "traits": objProp("Group traits"),
                                      "options": objProp("RudderOption: integrations, customContext, externalIds")],
                                     required: ["groupId"])),
            
            Tool(name: "rudder.alias",
                 description: "Alias a user identity.",
                 inputSchema: schema(["newId": strProp("New user ID"),
                                      "previousId": strProp("Previous user ID"),
                                      "options": objProp("RudderOption: integrations, customContext, externalIds")],
                                     required: ["newId"])),
            
            Tool(name: "rudder.flush",
                 description: "Flush all pending events to the data plane.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.reset",
                 description: "Reset the SDK state.",
                 inputSchema: schema(["options": objProp("Reset options: anonymousId, userId, traits, session (booleans)")])),
            
            Tool(name: "rudder.background",
                 description: "Send the app to the background.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.foreground",
                 description: "Bring the app to the foreground.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.kill",
                 description: "Terminate the app process.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.coldStart",
                 description: "Kill and relaunch the app from scratch.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.networkOffline",
                 description: "Simulate the data plane becoming unreachable.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.networkOnline",
                 description: "Restore normal data plane connectivity.",
                 inputSchema: schema()),
            
            Tool(name: "rudder.waitForBatch",
                 description: "Block until the SDK sends a batch to the mock server.",
                 inputSchema: schema(["timeout": numProp("Timeout in seconds (default 5)")])),
            
            Tool(name: "rudder.assertNoEvent",
                 description: "Assert that a named event does NOT arrive within a time window.",
                 inputSchema: schema(["name": strProp("Event name"),
                                      "window": numProp("Time window in seconds (default 3)")],
                                     required: ["name"])),
            
            Tool(name: "rudder.readState",
                 description: "Read an SDK state value by key (e.g. anonymousId, userId).",
                 inputSchema: schema(["key": strProp("State key (anonymousId, userId, session)")],
                                     required: ["key"])),
            
            Tool(name: "rudder.list_scenarios",
                 description: "List available pre-built scenario packs.",
                 inputSchema: schema(["filter": strProp("Optional name filter")])),
            
            Tool(name: "rudder.run_scenario",
                 description: "Run a named pre-built scenario pack end-to-end.",
                 inputSchema: schema(["name": strProp("Scenario pack name")],
                                     required: ["name"])),
            
            Tool(name: "rudder.run_steps",
                 description: "Run a batch of steps encoded as JSON in one round-trip.",
                 inputSchema: schema(["steps": .object(["type": "array",
                                                        "description": "Array of step objects"])],
                                     required: ["steps"]))
        ]
    }
}

// MARK: - Tool Handling

extension MCPServer {
    
    private func handleToolCall(name: String, arguments args: [String: Value]?) -> CallTool.Result {
        do {
            switch name {
                
            case "rudder.init":
                let writeKey     = args?["writeKey"]?.stringValue ?? "test-key"
                let dataPlaneUrl = args?["dataPlaneUrl"]?.stringValue ?? interpreter.mockServer.baseURL
                let options      = toDict(args?["options"]) ?? [:]
                return callAndRecord(.initialize(writeKey: writeKey,
                                                 dataPlaneUrl: dataPlaneUrl,
                                                 options: options))
                
            case "rudder.track":
                return callAndRecord(.track(name: args?["name"]?.stringValue ?? "",
                                            properties: toDict(args?["properties"]),
                                            options: toDict(args?["options"])))
                
            case "rudder.identify":
                return callAndRecord(.identify(userId: args?["userId"]?.stringValue,
                                               traits: toDict(args?["traits"]),
                                               options: toDict(args?["options"])))
                
            case "rudder.screen":
                return callAndRecord(.screen(name: args?["name"]?.stringValue ?? "",
                                             category: args?["category"]?.stringValue,
                                             properties: toDict(args?["properties"]),
                                             options: toDict(args?["options"])))
                
            case "rudder.group":
                return callAndRecord(.group(groupId: args?["groupId"]?.stringValue ?? "",
                                            traits: toDict(args?["traits"]),
                                            options: toDict(args?["options"])))
                
            case "rudder.alias":
                return callAndRecord(.alias(newId: args?["newId"]?.stringValue ?? "",
                                            previousId: args?["previousId"]?.stringValue,
                                            options: toDict(args?["options"])))
                
            case "rudder.flush":
                return callAndRecord(.flush)
                
            case "rudder.reset":
                let resetOptions: [String: Bool]? = {
                    guard let obj = args?["options"]?.objectValue else { return nil }
                    var result: [String: Bool] = [:]
                    for key in ["anonymousId", "userId", "traits", "session"] {
                        if case .bool(let b) = obj[key] { result[key] = b }
                    }
                    return result.isEmpty ? nil : result
                }()
                return callAndRecord(.reset(options: resetOptions))
                
            case "rudder.background":     return callAndRecord(.background)
            case "rudder.foreground":     return callAndRecord(.foreground)
            case "rudder.kill":           return callAndRecord(.kill)
            case "rudder.coldStart":      return callAndRecord(.coldStart)
            case "rudder.networkOffline": return callAndRecord(.networkOffline)
            case "rudder.networkOnline":  return callAndRecord(.networkOnline)
                
            case "rudder.waitForBatch":
                return callAndRecord(.waitForBatch(timeout: args?["timeout"]?.doubleValue ?? 5))
                
            case "rudder.assertNoEvent":
                return callAndRecord(.assertNoEvent(name: args?["name"]?.stringValue ?? "",
                                                    window: args?["window"]?.doubleValue ?? 3))
                
            case "rudder.readState":
                let key = args?["key"]?.stringValue ?? ""
                var response: [String: Any?]?
                var readError: Error?
                executeQueue.sync {
                    do { response = try interpreter.sutClient.get("/state/\(key)") }
                    catch { readError = error }
                }
                if let error = readError { throw error }
                let value = response?["value"].map { "\($0 as Any)" } ?? ""
                return CallTool.Result(content: [.text(text: value, annotations: nil, _meta: nil)])
                
            case "rudder.list_scenarios":
                let list = PackRegistry.shared.list(filter: args?["filter"]?.stringValue)
                let json = (try? JSONSerialization.data(withJSONObject: list))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                return CallTool.Result(content: [.text(text: json, annotations: nil, _meta: nil)])
                
            case "rudder.run_scenario":
                let scenarioName = args?["name"]?.stringValue ?? ""
                let steps        = try PackRegistry.shared.load(name: scenarioName)
                var runError: Error?
                executeQueue.sync {
                    do { try interpreter.run(steps) }
                    catch { runError = error }
                }
                if let error = runError { throw error }
                return ok()
                
            case "rudder.run_steps":
                let stepDicts = args?["steps"]?.arrayValue?.compactMap { toDict($0) } ?? []
                let steps     = stepDicts.compactMap { Step.decode($0) }
                var runError: Error?
                executeQueue.sync {
                    do { try interpreter.run(steps) }
                    catch { runError = error }
                }
                if let error = runError { throw error }
                return CallTool.Result(
                    content: [.text(text: "{\"status\":\"ok\",\"ran\":\(steps.count)}",
                                    annotations: nil, _meta: nil)]
                )
                
            default:
                return CallTool.Result(
                    content: [.text(text: "Unknown tool: \(name)", annotations: nil, _meta: nil)],
                    isError: true
                )
            }
        } catch ScenarioError.assertionFailed(let msg) {
            return CallTool.Result(
                content: [.text(text: msg, annotations: nil, _meta: nil)],
                isError: true
            )
        } catch {
            return CallTool.Result(
                content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)],
                isError: true
            )
        }
    }
    
    private func callAndRecord(_ step: Step) -> CallTool.Result {
        var executeError: Error?
        executeQueue.sync {
            do { try interpreter.execute(step) }
            catch { executeError = error }
        }
        if let error = executeError {
            if case ScenarioError.assertionFailed(let msg) = error {
                return CallTool.Result(
                    content: [.text(text: msg, annotations: nil, _meta: nil)],
                    isError: true
                )
            }
            return CallTool.Result(
                content: [.text(text: error.localizedDescription, annotations: nil, _meta: nil)],
                isError: true
            )
        }
        return ok()
    }
    
    private func ok() -> CallTool.Result {
        CallTool.Result(content: [.text(text: "{\"status\":\"ok\"}", annotations: nil, _meta: nil)])
    }
}

// MARK: - Schema Helpers

extension MCPServer {
    
    private func schema(_ properties: [String: Value] = [:], required: [String] = []) -> Value {
        var obj: [String: Value] = ["type": "object"]
        if !properties.isEmpty { obj["properties"] = .object(properties) }
        if !required.isEmpty   { obj["required"] = .array(required.map { .string($0) }) }
        return .object(obj)
    }
    
    private func strProp(_ description: String) -> Value {
        .object(["type": "string", "description": .string(description)])
    }
    
    private func numProp(_ description: String) -> Value {
        .object(["type": "number", "description": .string(description)])
    }
    
    private func objProp(_ description: String) -> Value {
        .object(["type": "object", "description": .string(description)])
    }
}

// MARK: - Value Conversion

extension MCPServer {
    
    private func valueToAny(_ value: Value) -> Any? {
        switch value {
        case .null:           return nil
        case .bool(let b):    return b
        case .int(let i):     return i
        case .double(let d):  return d
        case .string(let s):  return s
        case .array(let a):   return a.compactMap { valueToAny($0) }
        case .object(let o):  return o.compactMapValues { valueToAny($0) }
        case .data(_, let d): return d
        }
    }
    
    private func toDict(_ value: Value?) -> [String: Any]? {
        guard let obj = value?.objectValue else { return nil }
        return obj.compactMapValues { valueToAny($0) }
    }
}

// MARK: - HTTP Adapter

extension MCPServer {
    
    private func readHTTPRequest(from connection: NWConnection) async throws -> MCP.HTTPRequest? {
        var buffer    = Data()
        let separator = Data("\r\n\r\n".utf8)
        
        while buffer.range(of: separator) == nil {
            guard let chunk = try await receiveChunk(from: connection) else { return nil }
            buffer.append(chunk)
        }
        
        guard let sepRange = buffer.range(of: separator) else { return nil }
        let headerSection = Data(buffer[..<sepRange.lowerBound])
        var bodyBuffer    = Data(buffer[sepRange.upperBound...])
        
        guard let headerStr = String(data: headerSection, encoding: .utf8) else { return nil }
        let lines = headerStr.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        
        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }
        
        let method = String(parts[0])
        let path   = String(parts[1]).components(separatedBy: "?").first ?? String(parts[1])
        
        var headers: [String: String] = [:]
        for line in lines.dropFirst() where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let val = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            headers[key] = val
        }
        
        let contentLength = headers.first { $0.key.lowercased() == "content-length" }
            .flatMap { Int($0.value) } ?? 0
        
        while bodyBuffer.count < contentLength {
            guard let chunk = try await receiveChunk(from: connection) else { break }
            bodyBuffer.append(chunk)
        }
        
        return MCP.HTTPRequest(
            method:  method,
            headers: headers,
            body:    contentLength > 0 ? Data(bodyBuffer.prefix(contentLength)) : nil,
            path:    path
        )
    }
    
    private func writeHTTPResponse(_ response: MCP.HTTPResponse, to connection: NWConnection) async {
        if case .stream(let stream, let headers) = response {
            await sendIdempotent(httpFrame(200, "OK", headers, nil), to: connection)
            do {
                for try await chunk in stream { await sendIdempotent(chunk, to: connection) }
            } catch {}
            connection.cancel()
            return
        }
        
        let code    = response.statusCode
        let body    = response.bodyData
        var headers = response.headers
        if let body { headers["Content-Length"] = "\(body.count)" }
        headers["Connection"] = "close"
        await sendFinal(httpFrame(code, httpStatus(code), headers, body), to: connection)
    }
    
    private func receiveChunk(from connection: NWConnection) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: data?.isEmpty == false ? data : nil) }
            }
        }
    }
    
    private func httpFrame(_ code: Int, _ status: String,
                           _ headers: [String: String], _ body: Data?) -> Data {
        var head = "HTTP/1.1 \(code) \(status)\r\n"
        for (k, v) in headers { head += "\(k): \(v)\r\n" }
        head += "\r\n"
        var data = Data(head.utf8)
        if let body { data.append(body) }
        return data
    }
    
    private func sendFinal(_ data: Data, to connection: NWConnection) async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            connection.send(content: data, completion: .contentProcessed { _ in
                connection.cancel()
                c.resume()
            })
        }
    }
    
    private func sendIdempotent(_ data: Data, to connection: NWConnection) async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            connection.send(content: data, completion: .contentProcessed { _ in c.resume() })
        }
    }
    
    private func httpStatus(_ code: Int) -> String {
        switch code {
        case 200: "OK"
        case 202: "Accepted"
        case 400: "Bad Request"
        case 404: "Not Found"
        case 405: "Method Not Allowed"
        case 406: "Not Acceptable"
        case 409: "Conflict"
        case 415: "Unsupported Media Type"
        case 421: "Misdirected Request"
        default:  "Error"
        }
    }
}
