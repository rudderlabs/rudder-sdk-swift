//
//  RudderStackDataPlanePlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/10/24.
//

import Foundation

public final class RudderStackDataPlanePlugin: MessagePlugin {
    
    var pluginType: PluginType = .destination
    var analytics: AnalyticsClient?
    
    private var messageQueue: DispatchQueue?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.messageQueue = DispatchQueue(label: "com.rudderlabs.analytics.messageQueue")
    }
    
    func flush() {
        
    }
}

extension RudderStackDataPlanePlugin {
    func track(payload: TrackEvent) -> (any Message)? {
        return nil
    }
    
    func screen(payload: ScreenEvent) -> (any Message)? {
        return nil
    }
    
    func group(payload: GroupEvent) -> (any Message)? {
        return nil
    }
    
    func flush(payload: FlushEvent) -> (any Message)? {
        return nil
    }
}
