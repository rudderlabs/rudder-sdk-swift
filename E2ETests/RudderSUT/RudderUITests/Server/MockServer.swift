//
//  MockServer.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

class MockServer {

    // MARK: - Types

    struct MockResponse {
        var statusCode: Int
        var body: String
        var delaySeconds: Double
    }

    // MARK: - Properties

    private let server = HTTPServer()
    private var receivedBatches: [[String: Any]] = []
    private var responseOverrides: [String: MockResponse] = [:]
    private let lock = NSLock()

    var baseURL: String { "http://127.0.0.1:\(server.port)" }
}

// MARK: - Lifecycle

extension MockServer {

    func start() {
        registerRoutes()
        server.start()
    }
}

// MARK: - Route Registration

extension MockServer {

    private func registerRoutes() {
        server.on("GET", "/sourceConfig") { [weak self] _ in
            guard let self else { return .text(500, "gone") }
            if let override = self.activeOverride("/sourceConfig") {
                Thread.sleep(forTimeInterval: override.delaySeconds)
                return .text(override.statusCode, override.body)
            }
            return .text(200, Self.defaultSourceConfig)
        }

        server.on("POST", "/v1/batch") { [weak self] request in
            guard let self else { return .text(500, "gone") }
            if let override = self.activeOverride("/v1/batch") {
                Thread.sleep(forTimeInterval: override.delaySeconds)
                return .text(override.statusCode, override.body)
            }
            if let body = String(data: request.body, encoding: .utf8) {
                self.recordBatch(body)
            }
            return .json(200, ["status": "ok"])
        }
    }
}

// MARK: - Overrides

extension MockServer {

    func install(path: String, statusCode: Int, body: String = "", delay: Double = 0) {
        lock.lock()
        responseOverrides[path] = MockResponse(statusCode: statusCode,
                                               body: body,
                                               delaySeconds: delay)
        lock.unlock()
    }

    func clearOverrides() {
        lock.lock()
        responseOverrides.removeAll()
        lock.unlock()
    }

    func simulateOffline() {
        install(path: "/v1/batch", statusCode: 200, body: "", delay: 120)
    }

    func simulateOnline() {
        lock.lock()
        responseOverrides.removeValue(forKey: "/v1/batch")
        lock.unlock()
    }

    private func activeOverride(_ path: String) -> MockResponse? {
        lock.lock()
        defer { lock.unlock() }
        return responseOverrides[path]
    }
}

// MARK: - Batch Recording & Querying

extension MockServer {

    func lastBatch() -> [String: Any]? {
        lock.lock()
        defer { lock.unlock() }
        return receivedBatches.last
    }

    func currentBatchIndex() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return receivedBatches.count
    }

    func waitForBatch(timeout: TimeInterval = 5,
                      after startIndex: Int = 0,
                      where predicate: (([String: Any]) -> Bool)? = nil) -> [String: Any]? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            lock.lock()
            let match = receivedBatches.dropFirst(startIndex).first { predicate?($0) ?? true }
            lock.unlock()
            if let match { return match }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return nil
    }

    func requestLog() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? JSONSerialization.data(withJSONObject: receivedBatches,
                                                     options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8)
        else { return "[]" }
        return json
    }

    private func recordBatch(_ body: String) {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        lock.lock()
        receivedBatches.append(json)
        lock.unlock()
    }
}

// MARK: - Default Responses

extension MockServer {

    private static let defaultSourceConfig = """
    {
      "source": {
        "enabled": true,
        "writeKey": "test-key",
        "destinations": []
      }
    }
    """
}
