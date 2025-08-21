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
    
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    
    private var eventQueue: EventQueue?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.eventQueue = EventQueue(analytics: analytics)
    }
    
    deinit {
        self.eventQueue = nil
    }
    
    func flush() {
        self.eventQueue?.flush()
    }
}

// MARK: - Incoming Events

extension RudderStackDataPlanePlugin {
    
    func identify(payload: IdentifyEvent) -> (any Event)? {
        self.eventQueue?.put(payload)
        return payload
    }
    
    func track(payload: TrackEvent) -> (any Event)? {
        self.eventQueue?.put(payload)
        return payload
    }
    
    func screen(payload: ScreenEvent) -> (any Event)? {
        self.eventQueue?.put(payload)
        return payload
    }
    
    func group(payload: GroupEvent) -> (any Event)? {
        self.eventQueue?.put(payload)
        return payload
    }
    
    func alias(payload: AliasEvent) -> (any Event)? {
        self.eventQueue?.put(payload)
        return payload
    }
}
