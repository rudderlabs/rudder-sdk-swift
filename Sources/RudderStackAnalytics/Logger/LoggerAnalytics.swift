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

 **DEPRECATED**: This class is deprecated in favor of instance-based logging. Migrate as follows:

 ### Configuring logger and log level
 Pass `logger` and `logLevel` via `Configuration` when initializing the SDK:
 ```swift
 let analytics = Analytics(
     configuration: Configuration(
         writeKey: "YOUR_WRITE_KEY",
         dataPlaneUrl: "YOUR_DATA_PLANE_URL",
         logger: SwiftLogger(),
         logLevel: .verbose
     )
 )
 ```

 ### Logging inside a custom plugin
 Use the `logger` property available on the `Plugin` protocol extension:
 ```swift
 class MyPlugin: Plugin {
     func intercept(event: Event) -> Event? {
         logger.verbose("Processing event")
         return event
     }
 }
 ```

 This class remains available for backward compatibility but should not be used in new code.
 */
@available(*, deprecated, message: "Pass logger and logLevel via Configuration instead. Inside a custom plugin, use the `logger` property available on the Plugin protocol.")
public final class LoggerAnalytics {
    
    // MARK: - Private Properties
    
    private init() {
        /* Default implementation (no-op) */
    }
    
    private static let shared = LoggerAnalytics()
    
    private var logger: Logger = SwiftLogger()
    
    private var currentLogLevel: LogLevel = Constants.log.defaultLevel
    
    // MARK: - Setup
    
    /**
     Gets or sets the global log level for analytics logging.

     When set to a specific level, only logs of that level or higher severity will be processed.
     */
    @available(*, deprecated, message: "Pass logLevel via Configuration instead for per-instance logging.")
    public static var logLevel: LogLevel {
        get { shared.currentLogLevel }
        set { shared.currentLogLevel = newValue }
    }

    /**
     Sets the logger implementation to be used for all logging operations.

     - Parameter logger: The `Logger` implementation to be used.
     */
    @available(*, deprecated, message: "Pass the logger instance via Configuration instead for per-instance logging.")
    public static func setLogger(_ logger: Logger) {
        shared.logger = logger
    }

    // MARK: - Log Methods

    /**
     Logs a verbose message if the current log level allows it.

     - Parameter log: The verbose message to be logged.
     */
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via Configuration, then inside a custom plugin, call logger.verbose(log:).")
    public static func verbose(_ log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.verbose.rawValue else { return }
        shared.logger.verbose(log: log)
    }

    /**
     Logs a debug message if the current log level allows it.

     - Parameter log: The debug message to be logged.
     */
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via Configuration, then inside a custom plugin, call logger.debug(log:).")
    public static func debug(_ log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.debug.rawValue else { return }
        shared.logger.debug(log: log)
    }

    /**
     Logs an info message if the current log level allows it.

     - Parameter log: The info message to be logged.
     */
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via Configuration, then inside a custom plugin, call logger.info(log:).")
    public static func info(_ log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.info.rawValue else { return }
        shared.logger.info(log: log)
    }

    /**
     Logs a warning message if the current log level allows it.

     - Parameter log: The warning message to be logged.
     */
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via Configuration, then inside a custom plugin, call logger.warn(log:).")
    public static func warn(_ log: String) {
        guard shared.currentLogLevel.rawValue >= LogLevel.warn.rawValue else { return }
        shared.logger.warn(log: log)
    }

    /**
     Logs an error message if the current log level allows it.

     - Parameters:
       - log: The error message to be logged.
       - cause: An optional `Error` instance to be included with the log.
     */
    @available(*, deprecated, message: "Use instance-based logging instead. Configure logger and logLevel via Configuration, then inside a custom plugin, call logger.error(log:error:).")
    public static func error(_ log: String, cause: Error? = nil) {
        guard shared.currentLogLevel.rawValue >= LogLevel.error.rawValue else { return }
        shared.logger.error(log: log, error: cause)
    }
}
