//
//  TimeZoneInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import Foundation

// MARK: - TimeZoneInfoPlugin
/**
 A plugin created to append timezone information to the message context.
 */
final class TimeZoneInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return event.append(info: ["timezone": self.preparedTimezoneInfo])
    }
    
    private var preparedTimezoneInfo: String {
        return TimeZone.current.identifier
    }
}
