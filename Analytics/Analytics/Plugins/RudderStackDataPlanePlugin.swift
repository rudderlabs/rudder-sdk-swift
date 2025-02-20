//
//  RudderStackDataPlanePlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/10/24.
//

import Foundation
// MARK: - RudderStackDataPlanePlugin
/**
 This class serves as the main plugin responsible for initiating message operations.
 */
final class RudderStackDataPlanePlugin: MessagePlugin {
    
    var pluginType: PluginType = .destination
    var analytics: AnalyticsClient?
    
    private var messageManager: EventManager?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.messageManager = EventManager(analytics: analytics)
    }
    
    deinit {
        self.messageManager?.stop()
        self.messageManager = nil
    }
    
    func flush() {
        self.messageManager?.flush()
    }
}

// MARK: - Message Events

extension RudderStackDataPlanePlugin {
    
    func identify(payload: IdentifyEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func track(payload: TrackEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func screen(payload: ScreenEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func group(payload: GroupEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func alias(payload: AliasEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func flush(payload: FlushEvent) -> (any Event)? {
        self.messageManager?.put(payload)
        return payload
    }
}
