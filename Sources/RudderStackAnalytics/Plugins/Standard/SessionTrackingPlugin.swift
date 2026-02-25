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
        
        let snapshot = sessionHandler.sessionSnapshot
        guard snapshot.id != SessionConstants.defaultSessionId else { return info }
        
        info["sessionId"] = snapshot.id
        if snapshot.isStart {
            info["sessionStart"] = true
            sessionHandler.updateSessionStart(isSessionStart: false)
        }
        
        if snapshot.type == .automatic {
            sessionHandler.updateSessionLastActivityTime()
        }
        return info
    }
}
