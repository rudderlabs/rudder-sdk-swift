//
//  EventFilteringPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - EventFilteringPlugin
/**
 This plugin filters out specific analytics events from being processed in the analytics pipeline. It allows you to prevent certain events from being tracked or sent to destinations.
 
 ## Usage:
 ```swift
 // Create and add the plugin
 let eventFilteringPlugin = EventFilteringPlugin()
 analytics.add(plugin: eventFilteringPlugin)
 ```
*/
final class EventFilteringPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    
    private var eventsToFilter = [String]()
    
    /** Called when the plugin is added to the analytics instance */
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.eventsToFilter = ["Application Opened", "Application Backgrounded"]
    }
    
    /** 
     Intercepts analytics events and filters out specified track events
     
     - Parameter event: The event to potentially filter
     - Returns: The original event if it should be processed, or nil if it should be filtered out
     */
    func intercept(event: any Event) -> (any Event)? {
        if let trackEvent = event as? TrackEvent, self.eventsToFilter.contains(trackEvent.event) {
            LoggerAnalytics.verbose("EventFilteringPlugin: Event \"\(trackEvent.event)\" is filtered out.")
            return nil
        }
        return event
    }
    
    /** Called when the plugin is being removed or the analytics instance is being torn down */
    func teardown() {
        self.eventsToFilter.removeAll()
    }
}
