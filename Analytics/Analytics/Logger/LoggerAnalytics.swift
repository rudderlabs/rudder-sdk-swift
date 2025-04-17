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

final class LoggerAnalytics {
    
    // MARK: - Private Properties

    private init() {
        // Default implementation is a no-op singleton
    }

    private static let shared = LoggerAnalytics()

    private var logger: Logger = SwiftLogger()
    private var logLevel: LogLevel = Constants.Log.defaultLevel

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

    static func verbose(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        shared.logger.verbose(log: log)
    }

    static func debug(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        shared.logger.debug(log: log)
    }

    static func info(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.info.rawValue else { return }
        shared.logger.info(log: log)
    }

    static func warn(log: String) {
        guard shared.logLevel.rawValue >= LogLevel.warn.rawValue else { return }
        shared.logger.warn(log: log)
    }

    static func error(log: String, error: Error?) {
        guard shared.logLevel.rawValue >= LogLevel.error.rawValue else { return }
        shared.logger.error(log: log, error: error)
    }
}
