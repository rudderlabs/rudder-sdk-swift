//
//  SwiftLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import Foundation

// MARK: - LogLevel

/**
 An enumeration that defines the levels of logging. Each level corresponds to an increasing severity of log messages.

 - Cases:
   - `none`: No logging.
   - `debug`: Detailed debugging information.
   - `info`: General informational messages.
   - `warn`: Warnings about potential issues.
   - `error`: Errors that occurred during execution.
 */
@objc
public enum LogLevel: Int {
    case none, debug, info, warn, error
}

// MARK: - Logger

/**
 A protocol that defines logging capabilities with support for multiple log levels.
 
 Implementers of this protocol can provide customized logging behavior based on the current log level.
 */
public protocol Logger {
    /**
     The current log level that determines which messages are logged.
     */
    var currentLogLevel: LogLevel { get }
    
    /**
     Activates the specified log level, which determines the severity of messages to log.
     
     - Parameter level: The desired log level.
     */
    func activate(level: LogLevel)
    
    /**
     Logs an informational message.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    func info(tag: String, log: String)
    
    /**
     Logs a debugging message.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    func debug(tag: String, log: String)
    
    /**
     Logs a warning message.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    func warn(tag: String, log: String)
    
    /**
     Logs an error message.
     
     - Parameters:
       - tag: A tag to categorize or identify the source of the log.
       - log: The message to log.
     */
    func error(tag: String, log: String)
}

public extension Logger {
    /**
     The current log level of the logger.
     */
    var currentLogLevel: LogLevel {
        get { .none }
    }

    /**
     Activates the logger with the specified log level.
     */
    func activate(level: LogLevel) {}

    /**
     Logs an informational message.
     */
    func info(tag: String, log: String) {}

    /**
     Logs a debug message.
     */
    func debug(tag: String, log: String) {}

    /**
     Logs a warning message.
     */
    func warn(tag: String, log: String) {}

    /**
     Logs an error message.
     */
    func error(tag: String, log: String) {}
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
        get {
            return self.logLevel
        }
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
