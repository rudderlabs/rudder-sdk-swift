//
//  ObjCLoggerAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

// MARK: - ObjCLoggerAnalytics

/**
 A static utility class to enable logging from Objective-C using the native Swift `LoggerAnalytics` system.
 
 **DEPRECATED**: Use `RSSConfigurationBuilder` to pass a logger and log level per Analytics instance instead.
 
 This class remains available for backward compatibility but should not be used in new code.
 */
@available(*, deprecated, message: "Pass logger and logLevel via RSSConfigurationBuilder instead. Inside a custom plugin, use analytics.logger.")
@objc(RSSLoggerAnalytics)
public final class ObjCLoggerAnalytics: NSObject {
    
    /** Private initializer to prevent instantiation. */
    private override init() {
        /* Default implementation (no-op) */
    }
    
    @available(*, deprecated, message: "Pass the logger instance via RSSConfigurationBuilder.setLogger(_:) instead for per-instance logging.")
    @objc
    public static func setLogger(_ logger: ObjCLogger) {
        LoggerAnalytics.setLogger(ObjCLoggerAdapter(logger: logger))
    }
    
    @available(*, deprecated, message: "Pass logLevel via RSSConfigurationBuilder.setLogLevel(_:) instead for per-instance logging.")
    @objc
    public static func setLogLevel(_ level: LogLevel) {
        LoggerAnalytics.logLevel = level
    }
    
    @available(*, deprecated, message: "Pass logLevel via RSSConfigurationBuilder.setLogLevel(_:) instead for per-instance logging.")
    @objc
    public static func getLogLevel() -> LogLevel {
        return LoggerAnalytics.logLevel
    }
    
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via RSSConfigurationBuilder, then inside a custom plugin, call analytics.logger.verbose(_:).")
    @objc
    public static func verbose(_ log: String) {
        LoggerAnalytics.verbose(log)
    }
    
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via RSSConfigurationBuilder, then inside a custom plugin, call analytics.logger.debug(_:).")
    @objc
    public static func debug(_ log: String) {
        LoggerAnalytics.debug(log)
    }
    
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via RSSConfigurationBuilder, then inside a custom plugin, call analytics.logger.info(_:).")
    @objc
    public static func info(_ log: String) {
        LoggerAnalytics.info(log)
    }
    
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via RSSConfigurationBuilder, then inside a custom plugin, call analytics.logger.warn(_:).")
    @objc
    public static func warn(_ log: String) {
        LoggerAnalytics.warn(log)
    }
    
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via RSSConfigurationBuilder, then inside a custom plugin, call analytics.logger.error(_:error:).")
    @objc
    public static func error(_ log: String, error: NSError?) {
        LoggerAnalytics.error(log, cause: error)
    }
}
