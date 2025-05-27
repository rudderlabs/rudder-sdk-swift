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
@objc(RSLoggerAnalytics)
public final class ObjCLoggerAnalytics: NSObject {
    
    /** Private initializer to prevent instantiation. */
    private override init() {
        /* Default implementation (no-op) */
    }

    /**
     Logs a verbose-level message using the underlying Swift logger.

     - Parameter log: The verbose message to log.
     */
    @objc
    public static func verbose(_ log: String) {
        LoggerAnalytics.verbose(log: log)
    }
    
    /**
     Logs a debug-level message using the underlying Swift logger.

     - Parameter log: The debug message to log.
     */
    @objc
    public static func debug(_ log: String) {
        LoggerAnalytics.debug(log: log)
    }
    
    /**
     Logs an informational message using the underlying Swift logger.

     - Parameter log: The info message to log.
     */
    @objc
    public static func info(_ log: String) {
        LoggerAnalytics.info(log: log)
    }
    
    /**
     Logs a warning-level message using the underlying Swift logger.

     - Parameter log: The warning message to log.
     */
    @objc
    public static func warn(_ log: String) {
        LoggerAnalytics.warn(log: log)
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
