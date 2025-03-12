//
//  SessionTrackingPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

/**
 A plugin created to append session information to the event context.
 */
final class SessionTrackingPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    var sessionManager: SessionManager?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.sessionManager = SessionManager(analytics: analytics)
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: self.prepareSessionInfo)
    }
    
    var prepareSessionInfo: [String: Any] {
        var info: [String: Any] = [:]
        guard let sessionManager = self.sessionManager, let sessionId = sessionManager.sessionId else { return info }
        info["sessionId"] = sessionId
        
        if sessionManager.isSessionStart {
            info["sessionStart"] = true
            sessionManager.updateSessionStart(isSessionStrat: false)
        }
        
        if sessionManager.sessionType == .automatic {
            sessionManager.updateSessionLastActivityTime()
        }
        return info
    }
}
