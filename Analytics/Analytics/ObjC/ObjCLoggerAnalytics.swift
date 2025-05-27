//
//  ObjCLoggerAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

@objc(RSLoggerAnalytics)
public final class ObjCLoggerAnalytics: NSObject {
    
    // Private init to prevent instantiation
    private override init() {
        /* Default implementation (no-op) */
    }

    /**
     Logs a verbose message.
     - Parameter log: The message to log.
     */
    @objc
    public static func verbose(_ log: String) {
        LoggerAnalytics.verbose(log: log)
    }
    
    /**
     Logs a debug message.
     - Parameter log: The message to log.
     */
    @objc
    public static func debug(_ log: String) {
        LoggerAnalytics.debug(log: log)
    }
    
    /**
     Logs an info message.
     - Parameter log: The message to log.
     */
    @objc
    public static func info(_ log: String) {
        LoggerAnalytics.info(log: log)
    }
    
    /**
     Logs a warning message.
     - Parameter log: The message to log.
     */
    @objc
    public static func warn(_ log: String) {
        LoggerAnalytics.warn(log: log)
    }
    
    /**
     Logs an error message.
     - Parameters:
        - log: The error message.
        - error: An optional `NSError` object.
     */
    @objc
    public static func error(_ log: String, error: NSError?) {
        LoggerAnalytics.error(log: log, error: error)
    }
}
