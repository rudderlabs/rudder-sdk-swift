//
//  RSLoggingPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

// MARK: - Plugin Implementation

internal class RSLoggingPlugin: RSUtilityPlugin {
    var filterKind = RSLogLevel.debug
    
    var client: RSClient? {
        didSet {
            addTargets()
        }
    }
    
    let type = PluginType.utility
    
    fileprivate var loggingMediator = [RSLoggingType: RSLogger]()
    
    // Default to no, enable to see local logs
    internal static var loggingEnabled = false
    
    // For internal use only. Note: This will contain the last created instance
    // of analytics when used in a multi-analytics environment.
    internal static var sharedAnalytics: RSClient?
    
    #if DEBUG
    internal static var globalLogger: RSLoggingPlugin {
        let logger = SegmentLog()
        logger.addTargets()
        return logger
    }
    #endif
    
    required init() { }
    
    func configure(client: RSClient) {
        self.client = client
        RSLoggingPlugin.sharedAnalytics = client
        addTargets()
    }
    
    internal func addTargets() {
        try? add(target: RSConsoleLogger(), for: RSLoggingType.log)
    }
    
    func loggingEnabled(_ enabled: Bool) {
        RSLoggingPlugin.loggingEnabled = enabled        
    }
    
    internal func log(_ logMessage: RSLogMessage, destination: RSLoggingType.LogDestination) {
        
        for (logType, target) in loggingMediator {
            if logType.contains(destination) {
                target.parseLog(logMessage)
            }
        }
    }
    
    internal func add(target: RSLogger, for loggingType: RSLoggingType) throws {
        
        // Verify the target does not exist, if it does bail out
        let filtered = loggingMediator.filter { (type: RSLoggingType, existingTarget: RSLogger) in
            Swift.type(of: existingTarget) == Swift.type(of: target)
        }
        if filtered.isEmpty == false { throw NSError(domain: "Target already exists", code: 2002, userInfo: nil) }
        
        // Finally add the target
        loggingMediator[loggingType] = target
    }
    
    internal func flush() {
        for (_, target) in loggingMediator {
            target.flush()
        }        
    }
}

// MARK: - Internal Types

internal struct LogFactory {
    static func buildLog(destination: RSLoggingType.LogDestination,
                         title: String,
                         message: String,
                         kind: RSLogLevel = .debug,
                         function: String? = nil,
                         line: Int? = nil,
                         event: RSMessage? = nil,
                         sender: Any? = nil,
                         value: Double? = nil,
                         tags: [String]? = nil) -> RSLogMessage {
        
        switch destination {
        case .log:
            return GenericLog(logLevel: kind, message: message, function: function, line: line)
        case .metric:
            return MetricLog(title: title, message: message, value: value ?? 1, event: event, function: function, line: line)
        }
    }
    
    fileprivate struct GenericLog: RSLogMessage {
        var logLevel: RSLogLevel
        var title: String?
        var message: String
        var event: RSMessage?
        var function: String?
        var line: Int?
        var logType: RSLoggingType.LogDestination = .log
        var dateTime = Date()
    }
    
    fileprivate struct MetricLog: RSLogMessage {
        var title: String?
        var logLevel: RSLogLevel = .debug
        var message: String
        var value: Double
        var event: RSMessage?
        var function: String?
        var line: Int?
        var logType: RSLoggingType.LogDestination = .metric
        var dateTime = Date()
    }
}

extension RSClient {
    static func rsLog(message: String, kind: RSLogLevel? = nil, function: String = #function, line: Int = #line) {
        if let shared = RSLoggingPlugin.sharedAnalytics {
            shared.apply { plugin in
                if let loggerPlugin = plugin as? RSLoggingPlugin {
                    var filterKind = loggerPlugin.filterKind
                    if let logKind = kind {
                        filterKind = logKind
                    }
                    
                    let log = LogFactory.buildLog(destination: .log, title: "", message: message, kind: filterKind, function: function, line: line)
                    loggerPlugin.log(log, destination: .log)
                }
            }
        } else {
            #if DEBUG
            let log = LogFactory.buildLog(destination: .log, title: "", message: message, logLevel: .debug, function: function, line: line)
            RSLoggingPlugin.globalLogger.log(log, destination: .log)
            #endif
        }
    }
    
    static func rsMetric(_ type: RSMetricType, name: String, value: Double, tags: [String]? = nil) {
        RSLoggingPlugin.sharedAnalytics?.apply { plugin in
            
            if let loggerPlugin = plugin as? RSLoggingPlugin {
                let log = LogFactory.buildLog(destination: .metric, title: type.toString(), message: name, value: value, tags: tags)
                loggerPlugin.log(log, destination: .metric)
            }
        }
    }
}
