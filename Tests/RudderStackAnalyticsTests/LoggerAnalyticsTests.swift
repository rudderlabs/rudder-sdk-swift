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
    
    var mockLogger: SwiftMockLogger
    
    init() {
        mockLogger = SwiftMockLogger()
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
        
        LoggerAnalytics.verbose("This is verbose")
        LoggerAnalytics.debug("This is debug")
        LoggerAnalytics.info("This is info")
        LoggerAnalytics.warn("This is warn")
        LoggerAnalytics.error("This is error")
        
        #expect(mockLogger.logs.isEmpty)
    }
}
