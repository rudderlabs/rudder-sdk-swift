//
//  ScenarioTestCase.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * ScenarioTestCase is the base class for all end-to-end (E2E) UI tests in the
 * RudderStack SDK test suite.
 *
 * It provides the foundational setup required to execute analytics scenarios,
 * including launching the application, discovering the communication port,
 * and initializing the MockServer and Interpreter. The `rudderScenario` helper
 * method serves as the entry point for writing clean, DSL-driven test cases.
 */
class ScenarioTestCase: XCTestCase {

    // MARK: - Properties

    private(set) var mockServer: MockServer?
    private(set) var interpreter: Interpreter?
}

// MARK: - DSL

extension ScenarioTestCase {

    func rudderScenario(
        initAnalytics: Bool = true,
        writeKey: String = "test-key",
        options: [String: Any] = [:],
        file: StaticString = #file,
        line: UInt = #line,
        body: (ScenarioContext) throws -> Void
    ) {
        let app        = XCUIApplication()
        let mockServer = MockServer()
        mockServer.start()

        app.launch()

        // Poll until the sut_port Text element has a valid port number as its label.
        // staticTexts covers SwiftUI Text views; the label equals the text content.
        let portElement = app.staticTexts.matching(identifier: "sut_port").firstMatch
        let portReady   = NSPredicate { _, _ in UInt16(portElement.label) != nil }
        let expectation = XCTNSPredicateExpectation(predicate: portReady, object: nil)
        guard XCTWaiter().wait(for: [expectation], timeout: 10) == .completed,
              let sutPort = UInt16(portElement.label)
        else {
            XCTFail("SUT did not publish its port within 10 seconds", file: file, line: line)
            return
        }

        let interpreter = Interpreter(app: app, sutPort: sutPort, mockServer: mockServer)
        self.mockServer  = mockServer
        self.interpreter = interpreter

        let ctx = ScenarioContext(interpreter: interpreter, mockServer: mockServer)

        do {
            if initAnalytics {
                try interpreter.execute(.initialize(writeKey: writeKey,
                                                    dataPlaneUrl: mockServer.baseURL,
                                                    options: options))
            }
            try body(ctx)
        } catch let ScenarioError.assertionFailed(msg) {
            XCTFail("Scenario failed: \(msg)", file: file, line: line)
        } catch {
            XCTFail("Scenario error: \(error)", file: file, line: line)
        }
    }
}
