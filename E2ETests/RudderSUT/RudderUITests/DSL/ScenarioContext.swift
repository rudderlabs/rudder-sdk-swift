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

    // MARK: - Init

    init(interpreter: Interpreter, mockServer: MockServer) {
        self.interpreter = interpreter
        self.mockServer  = mockServer
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

// MARK: - State Snapshot

extension ScenarioContext {

    func snapshot() throws { try interpreter.execute(.snapshotState) }

    func restoreSnapshot() throws {
        guard let blob = interpreter.savedStateBlob else { return }
        try interpreter.execute(.importState(blob: blob))
    }
}
