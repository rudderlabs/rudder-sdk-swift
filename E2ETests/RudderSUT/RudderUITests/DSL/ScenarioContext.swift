//
//  ScenarioContext.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * ScenarioContext provides a Domain-Specific Language (DSL) for writing test scenarios.
 *
 * It acts as a user-friendly wrapper around the Interpreter, offering a clean API
 * for tracking events, controlling the app lifecycle, and performing assertions.
 * By hiding the complexity of the underlying execution engine, it allows test
 * authors to focus on the behavioral logic of their test cases.
 */
class ScenarioContext {

    // MARK: - Properties

    let mockServer: MockServer
    private let interpreter: Interpreter
    let writeKey: String
    let dataPlaneUrl: String

    // MARK: - Init

    init(interpreter: Interpreter, mockServer: MockServer, writeKey: String, dataPlaneUrl: String) {
        self.interpreter  = interpreter
        self.mockServer   = mockServer
        self.writeKey     = writeKey
        self.dataPlaneUrl = dataPlaneUrl
    }
}

// MARK: - Events

extension ScenarioContext {

    func track(_ name: String, properties: [String: Any]? = nil, options: [String: Any]? = nil) throws {
        try interpreter.execute(.track(name: name, properties: properties, options: options))
    }

    func identify(_ userId: String? = nil, traits: [String: Any]? = nil, options: [String: Any]? = nil) throws {
        try interpreter.execute(.identify(userId: userId, traits: traits, options: options))
    }

    func screen(_ name: String, category: String? = nil, properties: [String: Any]? = nil, options: [String: Any]? = nil) throws {
        try interpreter.execute(.screen(name: name, category: category, properties: properties, options: options))
    }

    func group(_ groupId: String, traits: [String: Any]? = nil, options: [String: Any]? = nil) throws {
        try interpreter.execute(.group(groupId: groupId, traits: traits, options: options))
    }

    func alias(_ newId: String, previousId: String? = nil, options: [String: Any]? = nil) throws {
        try interpreter.execute(.alias(newId: newId, previousId: previousId, options: options))
    }
}

// MARK: - SDK Control

extension ScenarioContext {

    func initialize(options: [String: Any] = [:]) throws {
        try interpreter.execute(.initialize(writeKey: writeKey, dataPlaneUrl: dataPlaneUrl, options: options))
    }

    func reset(options: [String: Bool]? = nil) throws {
        try interpreter.execute(.reset(options: options))
    }

    func flush() throws { try interpreter.execute(.flush) }
}

// MARK: - Lifecycle

extension ScenarioContext {

    func background() throws  { try interpreter.execute(.background) }
    func foreground() throws  { try interpreter.execute(.foreground) }
    func kill() throws        { try interpreter.execute(.kill) }
    func coldStart() throws   { try interpreter.execute(.coldStart) }
}

// MARK: - Network

extension ScenarioContext {

    func networkOffline() throws { try interpreter.execute(.networkOffline) }
    func networkOnline() throws  { try interpreter.execute(.networkOnline) }
}

// MARK: - Assertions

extension ScenarioContext {

    func waitForBatch(timeout: TimeInterval = 5) throws {
        try interpreter.execute(.waitForBatch(timeout: timeout))
    }

    func assertNoEvent(_ name: String, window: TimeInterval = 3) throws {
        try interpreter.execute(.assertNoEvent(name: name, window: window))
    }

    func assertState(_ key: String, equals expected: Any) throws {
        try interpreter.execute(.assertState(key: key, expected: expected))
    }

    func readState(_ key: String) throws -> String {
        let response = try interpreter.sutClient.get("/state/\(key)")
        return response["value"].map { "\($0)" } ?? ""
    }
}

// MARK: - Batch Inspection

extension ScenarioContext {

    /// Returns the first event in the last received batch matching the given predicate.
    func lastEvent(where predicate: ([String: Any]) -> Bool) -> [String: Any]? {
        guard let events = mockServer.lastBatch()?["batch"] as? [[String: Any]] else { return nil }
        return events.first(where: predicate)
    }

    /// Returns the first event in the last batch whose `event` field equals `name` (track / screen).
    func lastEvent(named name: String) -> [String: Any]? {
        lastEvent(where: { $0["event"] as? String == name })
    }

    /// Returns the first event in the last batch whose `type` field equals `type`.
    func lastEvent(ofType type: String) -> [String: Any]? {
        lastEvent(where: { $0["type"] as? String == type })
    }
}

// MARK: - State Snapshot

extension ScenarioContext {

    func snapshot() throws { try interpreter.execute(.snapshotState) }

    func restoreSnapshot() throws {
        guard let blob = interpreter.savedStateBlob else { return }
        try interpreter.execute(.importState(blob: blob))
    }
}
