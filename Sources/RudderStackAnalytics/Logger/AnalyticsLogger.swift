//
//  AnalyticsLogger.swift
//  Analytics
//
//  Created by Satheesh Kannan on 28/04/26.
//

import Foundation

// MARK: - AnalyticsLogger

/**
 Internal per-instance logger that applies log-level filtering before delegating to the underlying Logger.
 */
final class AnalyticsLogger: Logger {
    private let logger: Logger
    private let logLevel: LogLevel

    init(logger: Logger, logLevel: LogLevel) {
        self.logger = logger
        self.logLevel = logLevel
    }

    func verbose(log: String) {
        guard logLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        logger.verbose(log: log)
    }

    func debug(log: String) {
        guard logLevel.rawValue >= LogLevel.debug.rawValue else { return }
        logger.debug(log: log)
    }

    func info(log: String) {
        guard logLevel.rawValue >= LogLevel.info.rawValue else { return }
        logger.info(log: log)
    }

    func warn(log: String) {
        guard logLevel.rawValue >= LogLevel.warn.rawValue else { return }
        logger.warn(log: log)
    }

    func error(log: String, error: Error?) {
        guard logLevel.rawValue >= LogLevel.error.rawValue else { return }
        logger.error(log: log, error: error)
    }
}
