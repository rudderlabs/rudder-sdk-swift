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
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: self.prepareSessionInfo)
    }
    
    var prepareSessionInfo: [String: Any] {
        var info: [String: Any] = [:]
        guard let sessionHandler = self.analytics?.sessionHandler, let sessionId = sessionHandler.sessionId else { return info }
        info["sessionId"] = sessionId
        
        if sessionHandler.isSessionStart {
            info["sessionStart"] = true
            sessionHandler.updateSessionStart(isSessionStrat: false)
        }
        
        if sessionHandler.sessionType == .automatic {
            sessionHandler.updateSessionLastActivityTime()
        }
        return info
    }
}
