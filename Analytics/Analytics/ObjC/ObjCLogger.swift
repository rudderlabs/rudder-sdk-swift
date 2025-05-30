//
//  ObjCLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

// MARK: - ObjCLogger
/**
 A protocol to enable Objective-C integration for logging at multiple levels.
 
 Implement any of the optional methods to receive SDK log messages.
 */
@objc(RSALogger)
public protocol ObjCLogger {

    /**
     Called when a verbose log is emitted.

     - Parameter log: The verbose log message.
     */
    @objc
    optional func verbose(_ log: String)

    /**
     Called when a debug log is emitted.

     - Parameter log: The debug log message.
     */
    @objc
    optional func debug(_ log: String)

    /**
     Called when an informational log is emitted.

     - Parameter log: The info log message.
     */
    @objc
    optional func info(_ log: String)

    /**
     Called when a warning log is emitted.

     - Parameter log: The warning log message.
     */
    @objc
    optional func warn(_ log: String)

    /**
     Called when an error log is emitted.

     - Parameters:
       - log: The error log message.
       - error: An optional `Error` providing additional details.
     */
    @objc
    optional func errorLog(_ log: String, error: Error?)
}

// MARK: - ObjCLoggerAdapter
/**
 A bridge class that adapts an `ObjCLogger` to the SDK's native `Logger` interface.
 
 This allows log messages from Swift code to be forwarded to an Objective-C logger implementation.
 */
final class ObjCLoggerAdapter: Logger {

    /// The wrapped Objective-C logger instance.
    private var objcLogger: ObjCLogger

    /**
     Creates a new adapter with the provided Objective-C logger.

     - Parameter logger: An object conforming to `ObjCLogger`.
     */
    public init(logger: ObjCLogger) {
        self.objcLogger = logger
    }

    /**
     Forwards a verbose log message to the Objective-C logger, if implemented.

     - Parameter log: The verbose message.
     */
    public func verbose(log: String) {
        objcLogger.verbose?(log)
    }

    /**
     Forwards a debug log message to the Objective-C logger, if implemented.

     - Parameter log: The debug message.
     */
    public func debug(log: String) {
        objcLogger.debug?(log)
    }

    /**
     Forwards an informational log message to the Objective-C logger, if implemented.

     - Parameter log: The info message.
     */
    public func info(log: String) {
        objcLogger.info?(log)
    }

    /**
     Forwards a warning log message to the Objective-C logger, if implemented.

     - Parameter log: The warning message.
     */
    public func warn(log: String) {
        objcLogger.warn?(log)
    }

    /**
     Forwards an error log message and optional error to the Objective-C logger, if implemented.

     - Parameters:
       - log: The error message.
       - error: An optional `Error` with more context.
     */
    public func error(log: String, error: Error?) {
        objcLogger.errorLog?(log, error: error)
    }
}
