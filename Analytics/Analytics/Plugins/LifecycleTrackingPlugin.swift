//
//  LifecycleTrackingPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 10/03/25.
//

import Foundation

// MARK: - LifecycleTrackingPlugin
/**
 A plugin created to track app lifecycle events.
 */
final class LifecycleTrackingPlugin: Plugin {
    var pluginType: PluginType = .manual
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    deinit {}
}
