//
//  TimeZoneInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import Foundation

// MARK: - TimezoneInfoPlugin
/**
 A plugin created to append timezone information to the message context.
 */
final class TimezoneInfoPlugin: ContextInfoPlugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return self.append(info: ["timezone": AnyCodable(self.preparedTimezoneInfo)], to: event)
    }
    
    private var preparedTimezoneInfo: String {
        return TimeZone.current.identifier
    }
}
