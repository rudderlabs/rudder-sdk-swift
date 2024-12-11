//
//  OSInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

import UIKit

// MARK: - OSInfoPlugin
/**
 A plugin created to append OS information to the message context.
 */
final class OSInfoPlugin: ContextInfoPlugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return self.append(info: ["os": self.preparedOSInfo], to: event)
    }
    
    private var preparedOSInfo: [String: Any] {
        return ["name": UIDevice.current.systemName, "version": UIDevice.current.systemVersion]
    }
}
