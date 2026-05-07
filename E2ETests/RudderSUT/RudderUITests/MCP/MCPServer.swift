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
    private var serverTasks: [Task<Void, Never>] = []
    private(set) var recordedSteps: [Step] = []
    private let lock = NSLock()
    
    init(interpreter: Interpreter) {
        self.interpreter = interpreter
    }
}

// MARK: - Lifecycle

extension MCPServer {

    func start(port: UInt16 = 7777) {
        guard let nwPort = NWEndpoint.Port(rawValue: port),
              let listener = try? NWListener(using: .tcp, on: nwPort)
        else {
            print("[MCPServer] Failed to start on port \(port)")
            return
        }
        self.listener = listener

        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            let task = Task { await self.serve(connection: connection) }
            self.lock.withLock { self.serverTasks.append(task) }
        }

        listener.start(queue: .global(qos: .userInitiated))
        print("[MCPServer] Listening on port \(port)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
        lock.withLock {
            serverTasks.forEach { $0.cancel() }
            serverTasks.removeAll()
        }
    }
}

// MARK: - Connection Handling

extension MCPServer {

    private func serve(connection: NWConnection) async {
        let transport = NetworkTransport(
            connection: connection,
            heartbeatConfig: .disabled,
            reconnectionConfig: .disabled
        )

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
                                      "properties": objProp("Event properties")],
                                     required: ["name"])),

            Tool(name: "rudder.identify",
                 description: "Identify a user.",
                 inputSchema: schema(["userId": strProp("User ID"),
                                      "traits": objProp("User traits")],
                                     required: ["userId"])),

            Tool(name: "rudder.screen",
                 description: "Send a screen event to the SDK.",
                 inputSchema: schema(["name": strProp("Screen name"),
                                      "category": strProp("Screen category"),
                                      "properties": objProp("Screen properties")],
                                     required: ["name"])),

            Tool(name: "rudder.group",
                 description: "Associate user with a group.",
                 inputSchema: schema(["groupId": strProp("Group ID"),
                                      "traits": objProp("Group traits")],
                                     required: ["groupId"])),

            Tool(name: "rudder.alias",
                 description: "Alias a user identity.",
                 inputSchema: schema(["newId": strProp("New user ID")],
                                     required: ["newId"])),

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
                                            properties: toDict(args?["properties"])))

            case "rudder.identify":
                return callAndRecord(.identify(userId: args?["userId"]?.stringValue ?? "",
                                               traits: toDict(args?["traits"])))

            case "rudder.screen":
                return callAndRecord(.screen(name: args?["name"]?.stringValue ?? "",
                                             category: args?["category"]?.stringValue,
                                             properties: toDict(args?["properties"])))

            case "rudder.group":
                return callAndRecord(.group(groupId: args?["groupId"]?.stringValue ?? "",
                                            traits: toDict(args?["traits"])))

            case "rudder.alias":
                return callAndRecord(.alias(newId: args?["newId"]?.stringValue ?? ""))

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
                let key      = args?["key"]?.stringValue ?? ""
                let response = try interpreter.sutClient.get("/state/\(key)")
                let value    = response["value"].map { "\($0)" } ?? ""
                return CallTool.Result(content: [.text(text: value, annotations: nil, _meta: nil)])

            case "rudder.list_scenarios":
                let list = PackRegistry.shared.list(filter: args?["filter"]?.stringValue)
                let json = (try? JSONSerialization.data(withJSONObject: list))
                    .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                return CallTool.Result(content: [.text(text: json, annotations: nil, _meta: nil)])

            case "rudder.run_scenario":
                let scenarioName = args?["name"]?.stringValue ?? ""
                let steps        = try PackRegistry.shared.load(name: scenarioName)
                try interpreter.run(steps)
                return ok()

            case "rudder.run_steps":
                let stepDicts = args?["steps"]?.arrayValue?.compactMap { toDict($0) } ?? []
                let steps     = stepDicts.compactMap { Step.decode($0) }
                try interpreter.run(steps)
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
        do {
            try interpreter.execute(step)
            lock.withLock { recordedSteps.append(step) }
            return ok()
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
