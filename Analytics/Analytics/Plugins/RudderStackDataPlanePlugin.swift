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
    
    private var messageManager: MessageManager?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.messageManager = MessageManager(analytics: analytics)
    }
    
    deinit {
        self.messageManager?.stop()
        self.messageManager = nil
    }
}

// MARK: - Message Events

extension RudderStackDataPlanePlugin {
    func track(payload: TrackEvent) -> (any Message)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func screen(payload: ScreenEvent) -> (any Message)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func group(payload: GroupEvent) -> (any Message)? {
        self.messageManager?.put(payload)
        return payload
    }
    
    func flush(payload: FlushEvent) -> (any Message)? {
        self.messageManager?.put(payload)
        return payload
    }
}
