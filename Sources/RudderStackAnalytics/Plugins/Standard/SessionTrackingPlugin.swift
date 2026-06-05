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
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: self.prepareSessionInfo)
    }
    
    var prepareSessionInfo: [String: Any] {
        var info: [String: Any] = [:]
        guard let sessionHandler = self.analytics?.sessionHandler else { return info }
        
        let sessionSnapshot = sessionHandler.sessionSnapshot
        guard let sessionId = sessionSnapshot.sessionId else { return info }
        
        info["sessionId"] = sessionId
        
        if sessionSnapshot.isStart {
            info["sessionStart"] = true
            sessionHandler.updateSessionStart(isSessionStart: false)
        }
        
        if sessionSnapshot.type == .automatic && sessionHandler.shouldUpdateActivityTimeForEvent() {
            sessionHandler.updateSessionLastActivityTime()
        } else if sessionSnapshot.type == .automatic {
            LoggerAnalytics.debug("SessionTrackingPlugin: Not updating activity time for event - app is in the background and background event updates are disabled.")
        }
        
        return info
    }
}
