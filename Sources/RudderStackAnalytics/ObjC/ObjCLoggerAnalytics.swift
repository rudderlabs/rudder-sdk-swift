//
//  ObjCLoggerAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

// MARK: - ObjCLoggerAnalytics
/**
 A static utility class to enable logging from Objective-C using the native Swift `LoggerAnalytics` system.

 This class provides Objective-C accessible static methods for logging at various levels.
 */
@objc(RSSLoggerAnalytics)
public final class ObjCLoggerAnalytics: NSObject {
    
    /** Private initializer to prevent instantiation. */
    private override init() {
        /* Default implementation (no-op) */
    }
    
    /**
     Sets the logger implementation to be used for all logging operations.
     
     - Parameter logger: The `RSSLogger` implementation to be used.
     */
    @objc
    public static func setLogger(_ logger: ObjCLogger) {
        LoggerAnalytics.setLogger(ObjCLoggerAdapter(logger: logger))
    }
    
    /**
     Sets the log level that determines which logs will be processed.
     
     - Parameter level: The log level to set `RSSLogLevel`.
     */
    @objc
    public static func setLogLevel(_ level: LogLevel) {
        LoggerAnalytics.logLevel = level
    }
    
    /**
     Gets the current log level.
     
     - Returns: The current log level as an `RSSLogLevel`.
     */
    @objc
    public static func getLogLevel() -> LogLevel {
        return LoggerAnalytics.logLevel
    }
    
    /**
     Logs a verbose-level message using the underlying Swift logger.

     - Parameter log: The verbose message to log.
     */
    @objc
    public static func verbose(_ log: String) {
        LoggerAnalytics.verbose(log)
    }
    
    /**
     Logs a debug-level message using the underlying Swift logger.

     - Parameter log: The debug message to log.
     */
    @objc
    public static func debug(_ log: String) {
        LoggerAnalytics.debug(log)
    }
    
    /**
     Logs an informational message using the underlying Swift logger.

     - Parameter log: The info message to log.
     */
    @objc
    public static func info(_ log: String) {
        LoggerAnalytics.info(log)
    }
    
    /**
     Logs a warning-level message using the underlying Swift logger.

     - Parameter log: The warning message to log.
     */
    @objc
    public static func warn(_ log: String) {
        LoggerAnalytics.warn(log)
    }
    
    /**
     Logs an error message using the underlying Swift logger.

     - Parameters:
       - log: The error message to log.
       - error: An optional `NSError` providing error details.
     */
    @objc
    public static func error(_ log: String, error: NSError?) {
        LoggerAnalytics.error(log: log, error: error)
    }
}
