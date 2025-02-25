//
//  SessionTrackingPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

final class SessionTrackingPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: self.prepareSessionInfo)
    }
    
    var prepareSessionInfo: [String: Any] {
        var info: [String: Any] = [:]
        guard let sessionManager = self.analytics?.sessionManager, let sessionId = sessionManager.sessionId else { return info }
        info["sessionId"] = String(sessionId)
        
        if sessionManager.isSessionStart {
            info["sessionStart"] = true
            sessionManager.updateSesstionStart(isSessionStrat: false)
        }
        
        return info
    }
}
