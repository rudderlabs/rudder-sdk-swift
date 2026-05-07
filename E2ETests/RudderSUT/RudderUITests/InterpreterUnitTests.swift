//
//  InterpreterUnitTests.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * InterpreterUnitTests provides a suite of fast-executing unit tests for the Interpreter class.
 *
 * By using a FakeSUTClient, it verifies that the Interpreter correctly translates
 * abstract test Steps into the expected network commands for the System Under Test (SUT).
 * This ensures the command-routing logic is sound without requiring a full UI test run
 * or a physical network connection.
 */
class InterpreterUnitTests: XCTestCase {

    // MARK: - Properties

    private var fakeSUT: FakeSUTClient!
    var mockServer: MockServer!
    var interpreter: Interpreter!
}

// MARK: - Setup

extension InterpreterUnitTests {

    override func setUp() {
        super.setUp()
        fakeSUT    = FakeSUTClient()
        mockServer = MockServer()
        interpreter = Interpreter(app: XCUIApplication(),
                                  sutClient: fakeSUT,
                                  mockServer: mockServer)
    }
}

// MARK: - Command Routing Tests

extension InterpreterUnitTests {

    func test_trackStep_sendsCorrectCommand() throws {
        try interpreter.execute(.track(name: "Purchase", properties: ["price": 99]))

        XCTAssertEqual(fakeSUT.lastPost?.path, "/command")
        XCTAssertEqual(fakeSUT.lastPost?.body["cmd"] as? String, "track")
        let args = fakeSUT.lastPost?.body["args"] as? [String: Any]
        XCTAssertEqual(args?["name"] as? String, "Purchase")
        XCTAssertEqual((args?["properties"] as? [String: Any])?["price"] as? Int, 99)
    }

    func test_identifyStep_sendsCorrectCommand() throws {
        try interpreter.execute(.identify(userId: "user_123", traits: ["plan": "pro"]))

        XCTAssertEqual(fakeSUT.lastPost?.path, "/command")
        XCTAssertEqual(fakeSUT.lastPost?.body["cmd"] as? String, "identify")
        let args = fakeSUT.lastPost?.body["args"] as? [String: Any]
        XCTAssertEqual(args?["userId"] as? String, "user_123")
    }

    func test_resetStep_sendsCorrectCommand() throws {
        try interpreter.execute(.reset())

        XCTAssertEqual(fakeSUT.lastPost?.path, "/command")
        XCTAssertEqual(fakeSUT.lastPost?.body["cmd"] as? String, "reset")
    }
}

// MARK: - Step Recording Tests

extension InterpreterUnitTests {

    func test_executedSteps_recordedInOrder() throws {
        try interpreter.execute(.track(name: "Event A"))
        try interpreter.execute(.identify(userId: "user_1"))
        try interpreter.execute(.reset())

        XCTAssertEqual(interpreter.executedSteps.count, 3)
    }

    func test_networkOffline_doesNotThrow() {
        XCTAssertNoThrow(try interpreter.execute(.networkOffline))
    }

    func test_networkOnline_doesNotThrow() {
        interpreter.mockServer.simulateOffline()
        XCTAssertNoThrow(try interpreter.execute(.networkOnline))
    }
}

// MARK: - FakeSUTClient

private class FakeSUTClient: SUTClientProtocol {

    struct PostRequest {
        let path: String
        let body: [String: Any]
    }

    var posts: [PostRequest] = []
    var lastPost: PostRequest? { posts.last }
    var getResponses: [String: [String: Any]] = [:]

    @discardableResult
    func post(_ path: String, body: [String: Any]) throws -> [String: Any] {
        posts.append(PostRequest(path: path, body: body))
        return [:]
    }

    func get(_ path: String) throws -> [String: Any] {
        return getResponses[path] ?? [:]
    }
}
