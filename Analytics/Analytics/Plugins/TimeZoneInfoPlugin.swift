//
//  TimeZoneInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import Foundation

// MARK: - TimeZoneInfoPlugin
/**
 A plugin created to append timezone information to the event context.
 */
final class TimeZoneInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["timezone": self.preparedTimezoneInfo])
    }
    
    private var preparedTimezoneInfo: String {
        return TimeZone.current.identifier
    }
}
