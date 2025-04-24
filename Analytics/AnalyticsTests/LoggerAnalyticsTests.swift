//
//  LoggerAnalyticsTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 19/04/25.
//

import XCTest
@testable import Analytics

final class LoggerAnalyticsTests: XCTestCase {
    
    var mockLogger: MockLogger?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.mockLogger = MockLogger()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        self.mockLogger = nil
    }
    
    func testLoggerLogsAtCorrectLevels() {
        given("a mock logger and log level set to .info") {
            guard let mockLogger else { XCTFail("Mock logger not set up correctly"); return }
            LoggerAnalytics.setup(logger: mockLogger, logLevel: .info)
            
            when("calling each log method") {
                LoggerAnalytics.verbose(log: "This is verbose")
                LoggerAnalytics.debug(log: "This is debug")
                LoggerAnalytics.info(log: "This is info")
                LoggerAnalytics.warn(log: "This is warn")
                LoggerAnalytics.error(log: "This is error")
                
                then("only info, warn, and error messages should be logged") {
                    let loggedLevels = mockLogger.logs.map { $0.level }
                    XCTAssertFalse(loggedLevels.contains("VERBOSE"))
                    XCTAssertFalse(loggedLevels.contains("DEBUG"))
                    XCTAssertTrue(loggedLevels.contains("INFO"))
                    XCTAssertTrue(loggedLevels.contains("WARN"))
                    XCTAssertTrue(loggedLevels.contains("ERROR"))
                }
            }
        }
    }
    
    func testErrorLoggingWithAndWithoutErrorObject() {
        given("a mock logger and log level set to .error") {
            guard let mockLogger else { XCTFail("Mock logger not set up correctly"); return }
            LoggerAnalytics.setup(logger: mockLogger, logLevel: .error)
            
            when("calling error with and without an error object") {
                LoggerAnalytics.error(log: "Only log")
                LoggerAnalytics.error(log: "With error", error: NSError(domain: "Test", code: 1))
                
                then("both error messages should be captured") {
                    XCTAssertEqual(mockLogger.logs.count, 2)
                    XCTAssertTrue(mockLogger.logs[0].message.contains("Only log"))
                    XCTAssertTrue(mockLogger.logs[1].message.contains("With error"))
                }
            }
        }
    }
    
    func testNoLoggingWhenLevelIsNone() {
        given("a mock logger and log level set to .none") {
            guard let mockLogger else { XCTFail("Mock logger not set up correctly"); return }
            LoggerAnalytics.setup(logger: mockLogger, logLevel: .none)
            
            when("all log methods are called") {
                LoggerAnalytics.verbose(log: "V")
                LoggerAnalytics.debug(log: "D")
                LoggerAnalytics.info(log: "I")
                LoggerAnalytics.warn(log: "W")
                LoggerAnalytics.error(log: "E")
                
                then("no messages should be logged") {
                    XCTAssertTrue(mockLogger.logs.isEmpty)
                }
            }
        }
    }
}

class MockLogger: Logger {
    var logs: [(level: String, message: String)] = []
    
    func verbose(log: String) {
        logs.append(("VERBOSE", log))
    }
    
    func debug(log: String) {
        logs.append(("DEBUG", log))
    }
    
    func info(log: String) {
        logs.append(("INFO", log))
    }
    
    func warn(log: String) {
        logs.append(("WARN", log))
    }
    
    func error(log: String, error: Error?) {
        if let error {
            logs.append(("ERROR", "\(log) - \(error.localizedDescription)"))
        } else {
            logs.append(("ERROR", log))
        }
    }
}
