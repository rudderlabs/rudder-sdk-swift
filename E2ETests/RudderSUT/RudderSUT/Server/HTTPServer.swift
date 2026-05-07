//
//  HTTPServer.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Network
import Foundation

class HTTPServer {

    // MARK: - Types

    struct Request {
        let method: String
        let path: String
        let pathParams: [String: String]
        let body: Data

        var jsonBody: [String: Any]? {
            try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        }
    }

    enum Response {
        case text(Int, String)
        case json(Int, [String: Any])
    }

    typealias Handler    = (Request) -> Response
    typealias SSEHandler = (Request, NWConnection) -> Void

    // MARK: - Private Types

    private struct Route {
        let method: String
        let pattern: String
        let handler: Handler
    }

    private struct SSERoute {
        let pattern: String
        let handler: SSEHandler
    }

    // MARK: - Properties

    private var routes:    [Route]    = []
    private var sseRoutes: [SSERoute] = []
    private var listener:  NWListener?
    private let queue = DispatchQueue(label: "com.rudderstack.http-server", qos: .userInitiated)
    private(set) var port: UInt16 = 0
}

// MARK: - Route Registration

extension HTTPServer {

    func on(_ method: String, _ pattern: String, _ handler: @escaping Handler) {
        routes.append(Route(method: method, pattern: pattern, handler: handler))
    }

    func onSSE(_ pattern: String, _ handler: @escaping SSEHandler) {
        sseRoutes.append(SSERoute(pattern: pattern, handler: handler))
    }
}

// MARK: - Lifecycle

extension HTTPServer {

    func start() {
        do { listener = try NWListener(using: .tcp, on: 0) }
        catch { fatalError("[HTTPServer] Failed to create listener: \(error)") }

        let ready = DispatchSemaphore(value: 0)

        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.port = self?.listener?.port?.rawValue ?? 0
                ready.signal()
            case .failed(let error):
                fatalError("[HTTPServer] Listener failed: \(error)")
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] in self?.accept($0) }
        listener?.start(queue: queue)
        ready.wait()
    }
}

// MARK: - Connection Handling

extension HTTPServer {

    private func accept(_ conn: NWConnection) {
        conn.start(queue: queue)
        receive(conn, buffer: Data())
    }

    private func receive(_ conn: NWConnection, buffer: Data) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let self, error == nil else { return }
            var buf = buffer
            if let data { buf.append(data) }
            guard let request = self.parse(buf) else {
                self.receive(conn, buffer: buf)
                return
            }
            self.dispatch(request, conn: conn)
        }
    }

    private func dispatch(_ request: Request, conn: NWConnection) {
        if let (route, params) = matchedSSERoute(for: request) {
            let req = request.with(pathParams: params)
            let headers = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\n\r\n"
            conn.send(content: Data(headers.utf8), completion: .idempotent)
            route.handler(req, conn)
            return
        }

        if let (route, params) = matchedRoute(for: request) {
            let req = request.with(pathParams: params)
            conn.send(content: route.handler(req).encoded(),
                      completion: .contentProcessed { _ in conn.cancel() })
            return
        }

        conn.send(content: Response.text(404, "not found").encoded(),
                  completion: .contentProcessed { _ in conn.cancel() })
    }

    private func matchedSSERoute(for request: Request) -> (SSERoute, [String: String])? {
        for route in sseRoutes {
            if let params = match(pattern: route.pattern, path: request.path) {
                return (route, params)
            }
        }
        return nil
    }

    private func matchedRoute(for request: Request) -> (Route, [String: String])? {
        for route in routes where route.method == request.method {
            if let params = match(pattern: route.pattern, path: request.path) {
                return (route, params)
            }
        }
        return nil
    }
}

// MARK: - HTTP Parsing

extension HTTPServer {

    private func parse(_ data: Data) -> Request? {
        guard let raw = String(data: data, encoding: .utf8),
              let sep = raw.range(of: "\r\n\r\n") else { return nil }

        let lines = raw[..<sep.lowerBound].components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let path   = String(parts[1]).components(separatedBy: "?").first ?? String(parts[1])
        let headers = parseHeaders(from: lines.dropFirst())

        let contentLength = headers["content-length"].flatMap(Int.init) ?? 0
        let bodyData = Data(raw[sep.upperBound...].utf8)
        guard bodyData.count >= contentLength else { return nil }

        return Request(method: method, path: path, pathParams: [:],
                       body: bodyData.prefix(contentLength))
    }

    private func parseHeaders(from lines: any Collection<String>) -> [String: String] {
        Dictionary(
            lines.compactMap { line -> (String, String)? in
                guard let colon = line.firstIndex(of: ":") else { return nil }
                let key = line[..<colon].lowercased().trimmingCharacters(in: .whitespaces)
                let val = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                return (key, val)
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func match(pattern: String, path: String) -> [String: String]? {
        let patternParts = pattern.components(separatedBy: "/")
        let pathParts    = path.components(separatedBy: "/")
        guard patternParts.count == pathParts.count else { return nil }

        var params: [String: String] = [:]
        for (segment, value) in zip(patternParts, pathParts) {
            if segment.hasPrefix(":") {
                params[String(segment.dropFirst())] = value
            } else if segment != value {
                return nil
            }
        }
        return params
    }
}

// MARK: - Request Helpers

extension HTTPServer.Request {

    func with(pathParams: [String: String]) -> HTTPServer.Request {
        HTTPServer.Request(method: method, path: path, pathParams: pathParams, body: body)
    }
}

// MARK: - Response Encoding

extension HTTPServer.Response {

    func encoded() -> Data {
        switch self {
        case let .text(code, body):
            return frame(code: code, contentType: "text/plain", body: Data(body.utf8))
        case let .json(code, dict):
            let data = (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
            return frame(code: code, contentType: "application/json", body: data)
        }
    }

    private func frame(code: Int, contentType: String, body: Data) -> Data {
        let status = [200: "OK", 400: "Bad Request", 404: "Not Found"][code] ?? "Unknown"
        let head = "HTTP/1.1 \(code) \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        return Data(head.utf8) + body
    }
}
