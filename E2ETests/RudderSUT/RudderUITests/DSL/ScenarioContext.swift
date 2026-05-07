//
//  ScenarioContext.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

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

    func track(_ name: String, properties: [String: Any]? = nil) throws {
        try interpreter.execute(.track(name: name, properties: properties))
    }

    func identify(_ userId: String, traits: [String: Any]? = nil) throws {
        try interpreter.execute(.identify(userId: userId, traits: traits))
    }

    func screen(_ name: String, category: String? = nil, properties: [String: Any]? = nil) throws {
        try interpreter.execute(.screen(name: name, category: category, properties: properties))
    }

    func group(_ groupId: String, traits: [String: Any]? = nil) throws {
        try interpreter.execute(.group(groupId: groupId, traits: traits))
    }

    func alias(_ newId: String) throws {
        try interpreter.execute(.alias(newId: newId))
    }
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
