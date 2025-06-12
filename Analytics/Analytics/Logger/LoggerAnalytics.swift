//
//  LoggerAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 18/04/25.
//

import Foundation

// MARK: - LoggerAnalytics

/**
 A centralized logger used for logging analytics-related events based on a set log level.
 
 Usage:
 ```swift
 // Set log level
 LoggerAnalytics.logLevel = .verbose
 
 // Set custom logger
 LoggerAnalytics.setLogger(MyCustomLogger())
 
 // Log messages
 LoggerAnalytics.verbose(log: "Some message")
 LoggerAnalytics.debug(log: "Debug message")
 LoggerAnalytics.error(log: "Something went wrong", error: error)
 ```
 */

public final class LoggerAnalytics {
    
    // MARK: - Private Properties
    
    /**
     Private initializer to enforce singleton usage.
     */
    private init() {
        /* Default implementation (no-op) */
    }
    
    /**
     The shared singleton instance of LoggerAnalytics.
     */
    private static let shared = LoggerAnalytics()
    
    /**
     The current logger implementation.
     */
    private var logger: Logger?
    
    /**
     The current log level determining which log messages will be processed.
     */
    private var currentLogLevel: LogLevel = Constants.log.defaultLevel
    
    // MARK: - Setup
    
    /**
     Gets or sets the global log level for analytics logging.
     
     When set to a specific level, only logs of that level or higher severity will be processed.
     */
    public static var logLevel: LogLevel {
        get { shared.currentLogLevel }
        set { shared.currentLogLevel = newValue }
    }
    
    /**
     Sets the logger implementation to be used for all logging operations.
     
     - Parameter logger: The `Logger` implementation to be used.
     */
    public static func setLogger(_ logger: Logger) {
        shared.logger = logger
    }
    
    // MARK: - Log Methods
    
    /**
     Logs a verbose message if the current log level allows it.
     
     - Parameter log: The verbose message to be logged.
     */
    public static func verbose(log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        shared.logger?.verbose(log: log)
    }
    
    /**
     Logs a debug message if the current log level allows it.
     
     - Parameter log: The debug message to be logged.
     */
    public static func debug(log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.debug.rawValue else { return }
        shared.logger?.debug(log: log)
    }
    
    /**
     Logs an info message if the current log level allows it.
     
     - Parameter log: The info message to be logged.
     */
    public static func info(log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.info.rawValue else { return }
        shared.logger?.info(log: log)
    }
    
    /**
     Logs a warning message if the current log level allows it.
     
     - Parameter log: The warning message to be logged.
     */
    public static func warn(log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.warn.rawValue else { return }
        shared.logger?.warn(log: log)
    }
    
    /**
     Logs an error message if the current log level allows it.
     
     - Parameters:
     - log: The error message to be logged.
     - error: An optional `Error` instance to be included with the log.
     */
    public static func error(log: String, error: Error? = nil) {
        guard shared.currentLogLevel.rawValue >= LogLevel.error.rawValue else { return }
        shared.logger?.error(log: log, error: error)
    }
}
