//
//  LoggerAnalyticsTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 19/04/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("LoggerAnalytics Tests")
class LoggerAnalyticsTests {
    
    var mockLogger: MockLogger
    
    init() {
        mockLogger = MockLogger()
    }
    
    deinit {
        mockLogger.clearLogs()
    }
    
    @Test("given a mock logger with info level, when calling each log method, then only info/warn/error messages are logged")
    func testLoggerLogsAtCorrectLevels() {
        LoggerAnalytics.setLogger(mockLogger)
        LoggerAnalytics.logLevel = .info

        // Clear any logs captured from background activity.
        mockLogger.clearLogs()

        LoggerAnalytics.verbose("This is verbose")
        LoggerAnalytics.debug("This is debug")
        LoggerAnalytics.info("This is info")
        LoggerAnalytics.warn("This is warn")
        LoggerAnalytics.error("This is error")
        
        let loggedLabels = mockLogger.logs.map { $0.level }
        #expect(!loggedLabels.contains("VERBOSE"))
        #expect(!loggedLabels.contains("DEBUG"))
        #expect(loggedLabels.contains("INFO"))
        #expect(loggedLabels.contains("WARN"))
        #expect(loggedLabels.contains("ERROR"))
    }
    
    @Test("given a mock logger with error level, when logging error with and without error object, then both errors are logged with correct messages")
    func testErrorLoggingWithAndWithoutErrorObject() {
        LoggerAnalytics.setLogger(mockLogger)
        LoggerAnalytics.logLevel = .error

        let error = NSError(domain: "Test", code: 1)

        // Clear any logs captured from background activity.
        mockLogger.clearLogs()

        LoggerAnalytics.error("Only log")
        LoggerAnalytics.error("With error", cause: error)
        
        #expect(mockLogger.logs.count == 2)
        #expect(mockLogger.logs[0].message.contains("Only log"))
        #expect(mockLogger.logs[1].message.contains("With error"))
        #expect(mockLogger.logs[1].message.contains(error.localizedDescription))
    }
    
    @Test("given a mock logger with none level, when calling all log methods, then no logs are captured")
    func noLoggingWhenLevelIsNone() {
        LoggerAnalytics.setLogger(mockLogger)
        LoggerAnalytics.logLevel = .none

        // Clear any logs captured from background activity.
        mockLogger.clearLogs()

        LoggerAnalytics.verbose("This is verbose")
        LoggerAnalytics.debug("This is debug")
        LoggerAnalytics.info("This is info")
        LoggerAnalytics.warn("This is warn")
        LoggerAnalytics.error("This is error")
        
        #expect(mockLogger.logs.isEmpty)
    }
}

// MARK: - MockLogger

/**
 Captures log lines for assertions, from any thread.

 Tests that use this logger build a live `Analytics`, which keeps logging from its own background
 queues — the network client, the session handler, the source config provider — while the test body
 reads `logs`. Appending to a Swift array from two threads at once can reallocate its buffer under
 the other thread, so every access is held behind `logLock`.
 */
final class MockLogger: Logger {
    private var capturedLogs: [(level: String, message: String)] = []
    private let logLock = NSLock()
    
    var logs: [(level: String, message: String)] {
        logLock.lock()
        defer { logLock.unlock() }
        return capturedLogs
    }
    
    func verbose(log: String) {
        capture("VERBOSE", log)
    }
    
    func debug(log: String) {
        capture("DEBUG", log)
    }
    
    func info(log: String) {
        capture("INFO", log)
    }
    
    func warn(log: String) {
        capture("WARN", log)
    }
    
    func error(log: String, error: Error?) {
        if let error {
            capture("ERROR", "\(log) - \(error.localizedDescription)")
        } else {
            capture("ERROR", log)
        }
    }
    
    func clearLogs() {
        logLock.lock()
        capturedLogs.removeAll()
        logLock.unlock()
    }
    
    func hasLog(level: String, containing message: String) -> Bool {
        return logs.contains { $0.level == level && $0.message.contains(message) }
    }
    
    func logCount(for level: String) -> Int {
        return logs.filter { $0.level == level }.count
    }
    
    private func capture(_ level: String, _ message: String) {
        logLock.lock()
        defer { logLock.unlock() }
        capturedLogs.append((level, message))
    }
}
