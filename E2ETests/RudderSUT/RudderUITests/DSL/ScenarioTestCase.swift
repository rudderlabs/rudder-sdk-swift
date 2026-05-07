//
//  ScenarioTestCase.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

class ScenarioTestCase: XCTestCase {

    // MARK: - Properties

    private(set) var mockServer: MockServer?
    private(set) var interpreter: Interpreter?
}

// MARK: - DSL

extension ScenarioTestCase {

    @discardableResult
    func rudderScenario(
        initAnalytics: Bool = true,
        writeKey: String = "test-key",
        options: [String: Any] = [:],
        file: StaticString = #file,
        line: UInt = #line,
        body: (ScenarioContext) throws -> Void
    ) -> ScenarioResult {
        let app        = XCUIApplication()
        let mockServer = MockServer()
        mockServer.start()

        app.launchEnvironment["MOCK_SERVER_URL"] = mockServer.baseURL
        app.launch()

        let portElement = app.otherElements.matching(identifier: "sut_port").firstMatch
        guard portElement.waitForExistence(timeout: 5),
              let sutPort = UInt16(portElement.label)
        else {
            XCTFail("SUT did not publish its port within 5 seconds", file: file, line: line)
            return .failed("port discovery timeout")
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
            return .passed
        } catch let ScenarioError.assertionFailed(msg) {
            XCTFail("Scenario failed: \(msg)", file: file, line: line)
            return .failed(msg)
        } catch {
            XCTFail("Scenario error: \(error)", file: file, line: line)
            return .failed(error.localizedDescription)
        }
    }
}

// MARK: - Result

enum ScenarioResult {
    case passed
    case failed(String)
}
