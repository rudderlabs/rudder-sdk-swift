//
//  EventFilteringPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 31/07/25.
//

import Foundation
import RudderStackAnalytics

final class EventFilteringPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    
    private var eventsToFilter = [String]()
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.eventsToFilter = ["Application Opened", "Application Backgrounded"]
    }
    
    func intercept(event: any Event) -> (any Event)? {
        if let trackEvent = event as? TrackEvent, eventsToFilter.contains(trackEvent.event) {
            LoggerAnalytics.verbose(log: "EventFilteringPlugin: Event \"\(trackEvent.event)\" is filtered out.")
            return nil
        }
        return event
    }
    
    func teardown() {
        eventsToFilter.removeAll()
    }
}
