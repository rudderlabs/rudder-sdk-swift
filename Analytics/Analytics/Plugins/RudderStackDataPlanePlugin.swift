//
//  RudderStackDataPlanePlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/10/24.
//

import Foundation
// MARK: - RudderStackDataPlanePlugin
/**
 This class serves as the main plugin responsible for initiating event operations.
 */
final class RudderStackDataPlanePlugin: EventPlugin {
    
    var pluginType: PluginType = .destination
    var analytics: AnalyticsClient?
    
    private var eventManager: EventManager?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.eventManager = EventManager(analytics: analytics)
    }
    
    deinit {
        self.eventManager?.stop()
        self.eventManager = nil
    }
    
    func flush() {
        self.eventManager?.flush()
    }
}

// MARK: - Incoming Events

extension RudderStackDataPlanePlugin {
    
    func identify(payload: IdentifyEvent) -> (any Event)? {
        self.eventManager?.put(payload)
        return payload
    }
    
    func track(payload: TrackEvent) -> (any Event)? {
        self.eventManager?.put(payload)
        return payload
    }
    
    func screen(payload: ScreenEvent) -> (any Event)? {
        self.eventManager?.put(payload)
        return payload
    }
    
    func group(payload: GroupEvent) -> (any Event)? {
        self.eventManager?.put(payload)
        return payload
    }
    
    func alias(payload: AliasEvent) -> (any Event)? {
        self.eventManager?.put(payload)
        return payload
    }
}
