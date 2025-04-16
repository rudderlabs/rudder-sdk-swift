//
//  SwiftLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import Foundation

// MARK: - Logger

/**
 A protocol that defines logging capabilities with support for multiple log levels.
 
 Implementers of this protocol can provide customized logging behavior based on the current log level.
 */
public protocol Logger {
    
    /**
     Logs detailed informational message.
     
     - Parameters:
       - log: The message to log.
     */
    func verbose(log: String)
    
    /**
     Logs useful debugging message.
     
     - Parameters:
       - log: The message to log.
     */
    func debug(log: String)
    
    /**
     Logs an informational message.
     
     - Parameters:
       - log: The message to log.
     */
    func info(log: String)
    
    /**
     Logs a warning message.
     
     - Parameters:
       - log: The message to log.
     */
    func warn(log: String)
    
    /**
     Logs an error message.
     
     - Parameters:
       - log: The message to log.
       - error: An optional error associated with the message being logged.
     */
    func error(log: String, error: Error?)
}

public extension Logger {
    
    /**
     Logs detailed informational message.
     */
    func verbose(log: String) {
        /* Default implementation (no-op) */
    }
    
    /**
     Logs a debug message.
     */
    func debug(log: String) {
        /* Default implementation (no-op) */
    }
    
    /**
     Logs an informational message.
     */
    func info(log: String) {
        /* Default implementation (no-op) */
    }

    /**
     Logs a warning message.
     */
    func warn(log: String) {
        /* Default implementation (no-op) */
    }

    /**
     Logs an error message.
     */
    func error(log: String, error: Error?) {
        /* Default implementation (no-op) */
    }
}

// MARK: - LogLevel

/**
 An enumeration that defines the levels of logging. Each level corresponds to an increasing severity of log messages.

 - Cases:
    - `none`: No logging.
    - `error`: Errors that may still allow the app to run.
    - `warn`: Warnings about potential issues.
    - `info`: General informational messages.
    - `debug`: Useful debugging information.
    - `verbose`: Detailed messages for deep troubleshooting.
 */
@objc
public enum LogLevel: Int {
    case none, error, warn, info, debug, verbose
}

// MARK: - SwiftLogger

/**
 A concrete implementation of the `Logger` protocol that logs messages to the console.
 
 The `SwiftLogger` class supports configurable log levels, ensuring that only messages with a severity equal to or higher
 than the current log level are logged.

 - Note: Logs are prefixed with a constant tag defined in `Rudder-Analytics`.
 */
@objcMembers
public final class SwiftLogger: Logger {
    
    // MARK: - Properties

    /**
     The currently active log level for this logger instance.
     */
    private var logLevel: LogLevel
    
    public var currentLogLevel: LogLevel {
        return self.logLevel
    }
    
    // MARK: - Initialization

    /**
     Initializes a `SwiftLogger` with the specified log level.
     
     - Parameter logLevel: The initial log level for this logger.
     */
    public init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }
    
    // MARK: - Methods

    /**
     Activates the specified log level for this logger.
     
     - Parameter level: The desired log level.
     */
    public func activate(level: LogLevel) {
        self.logLevel = level
    }
    
    /**
     Logs an informational message if the current log level is `info` or higher.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    public func info(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.info.rawValue {
            print(Constants.Log.tag + "-info : \(log)")
        }
    }
    
    /**
     Logs a debugging message if the current log level is `debug` or higher.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    public func debug(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.debug.rawValue {
            print(Constants.Log.tag + "-debug : \(log)")
        }
    }
    
    /**
     Logs a warning message if the current log level is `warn` or higher.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    public func warn(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.warn.rawValue {
            print(Constants.Log.tag + "-warn : \(log)")
        }
    }
    
    /**
     Logs an error message if the current log level is `error` or higher.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    public func error(tag: String, log: String) {
        if self.logLevel.rawValue >= LogLevel.error.rawValue {
            print(Constants.Log.tag + "-error : \(log)")
        }
    }
}
