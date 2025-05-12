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
 */

public final class LoggerAnalytics {
    
    // MARK: - Private Properties
    
    private init() {
        // Default implementation is a no-op singleton
    }
    
    private static let shared = LoggerAnalytics()
    
    private var logger: Logger?
    private var logLevel: LogLevel = Constants.log.defaultLevel
    
    /**
     Sets up the logger and log level for analytics.
     
     - Parameters:
        - logger: A custom logger conforming to the `Logger` protocol.
        - logLevel: The minimum level of logs to be shown.
     */
    
    static func setup(logger: Logger, logLevel: LogLevel) {
        shared.logger = logger
        shared.logLevel = logLevel
    }
    
    // MARK: - Log Methods
    
    /**
     Logs a verbose message if the current log level allows it.
     
     - Parameter log: The verbose message to be logged.
     */
    public static func verbose(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        shared.logger?.verbose(log: log)
    }
    
    /**
     Logs a debug message if the current log level allows it.
     
     - Parameter log: The debug message to be logged.
     */
    public static func debug(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        shared.logger?.debug(log: log)
    }
    
    /**
     Logs an info message if the current log level allows it.
     
     - Parameter log: The info message to be logged.
     */
    public static func info(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.info.rawValue else { return }
        shared.logger?.info(log: log)
    }
    
    /**
     Logs a warning message if the current log level allows it.
     
     - Parameter log: The warning message to be logged.
     */
    public static func warn(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.warn.rawValue else { return }
        shared.logger?.warn(log: log)
    }
    
    /**
     Logs an error message if the current log level allows it.
     
     - Parameters:
     - log: The error message to be logged.
     - error: An optional `Error` instance to be included with the log.
     */
    public static func error(log: String, error: Error? = nil) {
        guard shared.logLevel.rawValue >= LogLevel.error.rawValue else { return }
        shared.logger?.error(log: log, error: error)
    }
}
