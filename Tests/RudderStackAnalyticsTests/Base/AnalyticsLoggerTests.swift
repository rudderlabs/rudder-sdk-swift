//
//  AnalyticsLoggerTests.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 28/04/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("AnalyticsLogger Tests")
class AnalyticsLoggerTests {

    var mockLogger: MockLogger

    init() {
        mockLogger = MockLogger()
    }

    deinit {
        mockLogger.clearLogs()
    }

    @Test("given a mock logger with info level, when calling each log method, then only info/warn/error messages are logged")
    func testLoggerLogsAtCorrectLevels() {
        let analyticsLogger = AnalyticsLogger(logger: mockLogger, logLevel: .info)

        analyticsLogger.verbose(log: "This is verbose")
        analyticsLogger.debug(log: "This is debug")
        analyticsLogger.info(log: "This is info")
        analyticsLogger.warn(log: "This is warn")
        analyticsLogger.error(log: "This is error", error: nil)

        let loggedLabels = mockLogger.logs.map { $0.level }
        #expect(!loggedLabels.contains("VERBOSE"))
        #expect(!loggedLabels.contains("DEBUG"))
        #expect(loggedLabels.contains("INFO"))
        #expect(loggedLabels.contains("WARN"))
        #expect(loggedLabels.contains("ERROR"))
    }

    @Test("given a mock logger with none level, when calling all log methods, then no logs are captured")
    func testNoLoggingWhenLevelIsNone() {
        let analyticsLogger = AnalyticsLogger(logger: mockLogger, logLevel: .none)

        analyticsLogger.verbose(log: "This is verbose")
        analyticsLogger.debug(log: "This is debug")
        analyticsLogger.info(log: "This is info")
        analyticsLogger.warn(log: "This is warn")
        analyticsLogger.error(log: "This is error", error: nil)

        #expect(mockLogger.logs.isEmpty)
    }

    @Test("given a mock logger with verbose level, when calling all log methods, then all messages are logged")
    func testAllLogsWhenLevelIsVerbose() {
        let analyticsLogger = AnalyticsLogger(logger: mockLogger, logLevel: .verbose)

        analyticsLogger.verbose(log: "This is verbose")
        analyticsLogger.debug(log: "This is debug")
        analyticsLogger.info(log: "This is info")
        analyticsLogger.warn(log: "This is warn")
        analyticsLogger.error(log: "This is error", error: nil)

        let loggedLabels = mockLogger.logs.map { $0.level }
        #expect(loggedLabels.contains("VERBOSE"))
        #expect(loggedLabels.contains("DEBUG"))
        #expect(loggedLabels.contains("INFO"))
        #expect(loggedLabels.contains("WARN"))
        #expect(loggedLabels.contains("ERROR"))
    }

    @Test("given a mock logger with error level, when logging error with and without error object, then both are logged with correct messages")
    func testErrorLoggingWithAndWithoutErrorObject() {
        let analyticsLogger = AnalyticsLogger(logger: mockLogger, logLevel: .error)
        let error = NSError(domain: "Test", code: 1)

        analyticsLogger.error(log: "Only log", error: nil)
        analyticsLogger.error(log: "With error", error: error)

        #expect(mockLogger.logs.count == 2)
        #expect(mockLogger.logs[0].message.contains("Only log"))
        #expect(mockLogger.logs[1].message.contains("With error"))
        #expect(mockLogger.logs[1].message.contains(error.localizedDescription))
    }

    @Test("given a mock logger with error level, when calling verbose/debug/info/warn, then none are logged")
    func testOnlyErrorLoggedWhenLevelIsError() {
        let analyticsLogger = AnalyticsLogger(logger: mockLogger, logLevel: .error)

        analyticsLogger.verbose(log: "This is verbose")
        analyticsLogger.debug(log: "This is debug")
        analyticsLogger.info(log: "This is info")
        analyticsLogger.warn(log: "This is warn")
        analyticsLogger.error(log: "This is error", error: nil)

        let loggedLabels = mockLogger.logs.map { $0.level }
        #expect(!loggedLabels.contains("VERBOSE"))
        #expect(!loggedLabels.contains("DEBUG"))
        #expect(!loggedLabels.contains("INFO"))
        #expect(!loggedLabels.contains("WARN"))
        #expect(loggedLabels.contains("ERROR"))
    }

    @Test("given two AnalyticsLogger instances with different log levels, when logging, then each filters independently")
    func testIndependentLogLevelPerInstance() {
        let verboseMock = MockLogger()
        let errorMock = MockLogger()

        let verboseLogger = AnalyticsLogger(logger: verboseMock, logLevel: .verbose)
        let errorLogger = AnalyticsLogger(logger: errorMock, logLevel: .error)

        verboseLogger.debug(log: "debug message")
        errorLogger.debug(log: "debug message")

        #expect(verboseMock.logs.count == 1)
        #expect(errorMock.logs.isEmpty)
    }
}
