//
//  CommandServer.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

/**
 * CommandServer serves as the high-level coordinator for the test app's remote interface.
 *
 * It initializes and manages an internal HTTPServer, defining the RESTful API endpoints
 * and SSE streams used by the test suite. It acts as the primary orchestrator that
 * routes incoming network requests to the appropriate handlers (like CommandDispatcher
 * or StateEndpoints) and manages the lifecycle of the communication layer.
 */
class CommandServer {

    // MARK: - Properties

    private let server = HTTPServer()
    let sseStream      = SSEStream()
    var port: UInt16   { server.port }
}

// MARK: - Lifecycle

extension CommandServer {

    func start() {
        registerRoutes()
        server.start()
        print("[SUT] HTTP server listening on port \(port)")
    }
}

// MARK: - Route Registration

extension CommandServer {

    private func registerRoutes() {
        server.on("GET",  "/health",       handleHealth)
        server.on("POST", "/command",      handleCommand)
        server.on("GET",  "/state/:key",   handleStateRead)
        server.on("POST", "/state/export", handleStateExport)
        server.on("POST", "/state/import", handleStateImport)
        server.onSSE("/event/stream") { [weak self] _, conn in
            self?.sseStream.addConnection(conn)
        }
    }
}

// MARK: - Handlers

extension CommandServer {

    private func handleHealth(_ request: HTTPServer.Request) -> HTTPServer.Response {
        .text(200, "ok")
    }

    private func handleCommand(_ request: HTTPServer.Request) -> HTTPServer.Response {
        guard let body = request.jsonBody, let cmd = body["cmd"] as? String else {
            return .text(400, "bad json")
        }
        let args   = body["args"] as? [String: Any] ?? [:]
        let result = CommandDispatcher.shared.dispatch(cmd: cmd, args: args)
        return .json(200, result)
    }

    private func handleStateRead(_ request: HTTPServer.Request) -> HTTPServer.Response {
        let key   = request.pathParams["key"] ?? ""
        let value = StateEndpoints.read(key: key)
        return .json(200, ["value": value as Any])
    }

    private func handleStateExport(_ request: HTTPServer.Request) -> HTTPServer.Response {
        .json(200, StateEndpoints.export())
    }

    private func handleStateImport(_ request: HTTPServer.Request) -> HTTPServer.Response {
        guard let blob = request.jsonBody else { return .text(400, "bad json") }
        StateEndpoints.restore(blob: blob)
        return .text(200, "ok")
    }
}
