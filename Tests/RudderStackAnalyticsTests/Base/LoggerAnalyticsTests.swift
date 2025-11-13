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
        
        LoggerAnalytics.verbose("This is verbose")
        LoggerAnalytics.debug("This is debug")
        LoggerAnalytics.info("This is info")
        LoggerAnalytics.warn("This is warn")
        LoggerAnalytics.error("This is error")
        
        let loggedLevels = mockLogger.logs.map { $0.level }
        #expect(!loggedLevels.contains("VERBOSE"))
        #expect(!loggedLevels.contains("DEBUG"))
        #expect(loggedLevels.contains("INFO"))
        #expect(loggedLevels.contains("WARN"))
        #expect(loggedLevels.contains("ERROR"))
    }
    
    @Test("given a mock logger with error level, when logging error with and without error object, then both errors are logged with correct messages")
    func testErrorLoggingWithAndWithoutErrorObject() {
        LoggerAnalytics.setLogger(mockLogger)
        LoggerAnalytics.logLevel = .error
        
        LoggerAnalytics.error("Only log")
        LoggerAnalytics.error("With error", cause: NSError(domain: "Test", code: 1))
        
        #expect(mockLogger.logs.count == 2)
        #expect(mockLogger.logs[0].message.contains("Only log"))
        #expect(mockLogger.logs[1].message.contains("With error"))
    }
    
    @Test("given a mock logger with none level, when calling all log methods, then no logs are captured")
    func noLoggingWhenLevelIsNone() {
        LoggerAnalytics.setLogger(mockLogger)
        LoggerAnalytics.logLevel = .none
        
        LoggerAnalytics.verbose("This is verbose")
        LoggerAnalytics.debug("This is debug")
        LoggerAnalytics.info("This is info")
        LoggerAnalytics.warn("This is warn")
        LoggerAnalytics.error("This is error")
        
        #expect(mockLogger.logs.isEmpty)
    }
}

// MARK: - MockLogger
final class MockLogger: Logger {
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
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func hasLog(level: String, containing message: String) -> Bool {
        return logs.contains { $0.level == level && $0.message.contains(message) }
    }
    
    func logCount(for level: String) -> Int {
        return logs.filter { $0.level == level }.count
    }
}
