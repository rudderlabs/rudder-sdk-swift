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
    
    func identify(payload: IdentifyEvent) {
        self.eventQueue?.put(payload)
    }
    
    func track(payload: TrackEvent) {
        self.eventQueue?.put(payload)
    }
    
    func screen(payload: ScreenEvent) {
        self.eventQueue?.put(payload)
    }
    
    func group(payload: GroupEvent) {
        self.eventQueue?.put(payload)
    }
    
    func alias(payload: AliasEvent) {
        self.eventQueue?.put(payload)
    }
}
