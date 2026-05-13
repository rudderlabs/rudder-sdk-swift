//
//  ObjCAnalyticsLogger.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 28/04/26.
//

import Foundation

// MARK: - ObjCAnalyticsLogger

/**
 An Objective-C wrapper around `AnalyticsLogger` that exposes per-instance logging to ObjC plugins.

 Obtain this via `ObjCAnalytics.logger` inside a plugin's `setup(_:)` method:
 ```objc
 - (void)setup:(RSSAnalytics *)analytics {
     self.logger = analytics.logger;
 }

 // Then log:
 [self.logger debug:@"MyPlugin: event received"];
 ```
 */
@objc(RSSAnalyticsLogger)
public final class ObjCAnalyticsLogger: NSObject {

    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    /** Logs a verbose message. */
    @objc
    public func verbose(_ log: String) {
        logger.verbose(log: log)
    }

    /** Logs a debug message. */
    @objc
    public func debug(_ log: String) {
        logger.debug(log: log)
    }

    /** Logs an informational message. */
    @objc
    public func info(_ log: String) {
        logger.info(log: log)
    }

    /** Logs a warning message. */
    @objc
    public func warn(_ log: String) {
        logger.warn(log: log)
    }

    /** Logs an error message with an optional error. */
    @objc
    public func error(_ log: String, error: NSError?) {
        logger.error(log: log, error: error)
    }
}
