//
//  LogTarget.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

// MARK: - Logging Types

/// The foundation for building out a special logger. If logs need to be directed to a certain area, this is the
/// interface to start off with. For instance a console logger, a networking logger or offline storage logger
/// would all start off with LogTarget.
protocol RSLogger {
    
    /// Implement this method to process logging messages. This is where the logic for the target will be
    /// added. Feel free to add your own data queueing and offline storage.
    /// - important: Use the Segment Network stack for Segment library compatibility and simplicity.
    func parseLog(_ log: RSLogMessage)
    
    /// Optional method to implement. This helps respond to potential queueing events being flushed out.
    /// Perhaps responding to backgrounding or networking events, this gives a chance to empty a queue
    /// or pump a firehose of logs.
    func flush()
}

extension RSLogger {
    // Make flush optional with an empty implementation.
    func flush() { }
}

/// The Segment logging system has three types of logs: log, metric and history. When adding a target that
/// responds to logs, it is possible to adhere to 1 to many. In other words, a LoggingType can be .log &
/// .history. This is used to tell which targets logs are directed to.
struct RSLoggingType: Hashable {
    
    enum LogDestination {
        case log
        case metric
    }
    
    /// Convenience .log logging type
    static let log = RSLoggingType(types: [.log])
    /// Convenience .metric logging type
    static let metric = RSLoggingType(types: [.metric])
    
    /// Designated initializer for LoggingType. Add all the destinations this LoggingType should support.
    /// - Parameter types: The LoggingDestination(s) that this LoggingType will support.
    init(types: [LogDestination]) {
        self.allTypes = types
    }
    
    // - Private Properties and Methods
    private let allTypes: [LogDestination]
    
    /// Convience method to find if the LoggingType supports a particular destination.
    /// - Parameter destination: The particular destination being tested for conformance.
    /// - Returns: If the destination exists in this LoggingType `true` or `false` will be returned.
    internal func contains(_ destination: LogDestination) -> Bool {
        return allTypes.contains(destination)
    }
}

/// The interface to the message being returned to `LogTarget` -> `parseLog()`.
protocol RSLogMessage {
    var logLevel: RSLogLevel { get }
    var title: String? { get }
    var message: String { get }
    var event: RSMessage? { get }
    var function: String? { get }
    var line: Int? { get }
    var logType: RSLoggingType.LogDestination { get }
    var dateTime: Date { get }
}

public enum RSMetricType: Int {
    case counter = 0    // Not Verbose
    case gauge          // Semi-verbose
    
    func toString() -> String {
        var typeString = "Gauge"
        if self == .counter {
            typeString = "Counter"
        }
        return typeString
    }
    
    static func fromString(_ string: String) -> Self {
        var returnType = Self.counter
        if string == "Gauge" {
            returnType = .gauge
        }
        
        return returnType
    }
}

// MARK: - Logging API

extension RSClient {
    
    /// The logging method for capturing all general types of log messages related to Segment.
    /// - Parameters:
    ///   - message: The main message of the log to be captured.
    ///   - kind: Usually .error, .warning or .debug, in order of serverity. This helps filter logs based on
    ///   this added metadata.
    ///   - function: The name of the function the log came from. This will be captured automatically.
    ///   - line: The line number in the function the log came from. This will be captured automatically.
    public func log(message: String, logLevel: RSLogLevel? = nil, function: String = #function, line: Int = #line) {
        apply { plugin in
            // Check if we should send off the event
            if RSLoggerPlugin.loggingEnabled == false {
                return
            }
            if let loggerPlugin = plugin as? RSLoggerPlugin {
                var filterKind = loggerPlugin.logLevel
                if let logKind = logLevel {
                    filterKind = logKind
                }
                
                let log = LogFactory.buildLog(destination: .log, title: "", message: message, logLevel: filterKind, function: function, line: line)
                loggerPlugin.log(log, destination: .log)
            }
        }
    }
    
    /// The logging method for capturing metrics related to Segment or other libraries.
    /// - Parameters:
    ///   - type: Metric type, usually .counter or .gauge. Select the one that makes sense for the metric.
    ///   - name: The title of the metric to track.
    ///   - value: The value associated with the metric. This would be an incrementing counter or time
    ///   or pressure gauge.
    ///   - tags: Any tags that should be associated with the metric. Any extra metadata that may help.
    public func metric(_ type: RSMetricType, name: String, value: Double, tags: [String]? = nil) {
        apply { plugin in
            // Check if we should send off the event
            if RSLoggerPlugin.loggingEnabled == false {
                return
            }
            
            if let loggerPlugin = plugin as? RSLoggerPlugin {
                
                let log = LogFactory.buildLog(destination: .metric, title: type.toString(), message: name, value: value, tags: tags)
                loggerPlugin.log(log, destination: .metric)
            }
        }
    }
}

extension RSClient {
    
    /// Add a logging target to the system. These `targets` can handle logs in various ways. Consider
    /// sending logs to the console, the OS and a web service. Three targets can handle these scenarios.
    /// - Parameters:
    ///   - target: A `LogTarget` that has logic to parse and handle log messages.
    ///   - type: The type consists of `log`, `metric` or `history`. These correspond to the
    ///   API on Analytics.
    func add(target: RSLogger, type: RSLoggingType) {
        apply { (potentialLogger) in
            if let logger = potentialLogger as? RSLoggerPlugin {
                do {
                    try logger.add(target: target, for: type)
                } catch {
                    Self.rsLog(message: "Could not add target: \(error.localizedDescription)", logLevel: .error)
                }
            }
        }
    }
    
    func logFlush() {
        apply { (potentialLogger) in
            if let logger = potentialLogger as? RSLoggerPlugin {
                logger.flush()
            }
        }
    }
}
