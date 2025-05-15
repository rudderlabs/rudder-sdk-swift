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
@objc
public protocol Logger {
    
    /**
     Logs detailed informational message.
     
     - Parameters:
       - log: The message to log.
     */
    @objc(verbose:)
    func verbose(log: String)
    
    /**
     Logs useful debugging message.
     
     - Parameters:
       - log: The message to log.
     */
    @objc(debug:)
    func debug(log: String)
    
    /**
     Logs an informational message.
     
     - Parameters:
       - log: The message to log.
     */
    @objc(info:)
    func info(log: String)
    
    /**
     Logs a warning message.
     
     - Parameters:
       - log: The message to log.
     */
    @objc(warn:)
    func warn(log: String)
    
    /**
     Logs an error message.
     
     - Parameters:
       - log: The message to log.
       - error: An optional error associated with the message being logged.
     */
    @objc(errorLog: error:)
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

 - Note: Logs are prefixed with a constant tag defined in `Rudder-Analytics`.
 */

final class SwiftLogger: Logger {
    
    private var tag = Constants.log.tag
    
    /**
     Logs an informational message if the current log level is `verbose`.
     
     - Parameters:
       - log: The message to log.
     */
    func verbose(log: String) {
        print("[\(tag)] VERBOSE: \(log)")
    }
    
    /**
     Logs a debugging message if the current log level is `debug` or higher.
     
     - Parameters:
       - log: The message to log.
     */
    func debug(log: String) {
        print("[\(tag)] DEBUG: \(log)")
    }
    
    /**
     Logs an informational message if the current log level is `info` or higher.
     
     - Parameters:
       - log: The message to log.
     */
    func info(log: String) {
        print("[\(tag)] INFO: \(log)")
    }
    
    /**
     Logs a warning message if the current log level is `warn` or higher.
     
     - Parameters:
       - log: The message to log.
     */
    func warn(log: String) {
        print("[\(tag)] WARN: \(log)")
    }
    
    /**
     Logs an error message if the current log level is `error` or higher.
     
     - Parameters:
       - log: The message to log.
       - error: Optional error to include in the message.
     */
    func error(log: String, error: (any Error)?) {
        if let error {
            print("[\(tag)] ERROR: \(log) - \(error.localizedDescription)")
        } else {
            print("[\(tag)] ERROR: \(log)")
        }
    }
}
