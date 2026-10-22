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
        return event.addToContext(info: self.sessionInfo(for: event))
    }
    
    private func sessionInfo(for event: any Event) -> [String: Any] {
        var info: [String: Any] = [:]
        guard let sessionHandler = self.analytics?.sessionHandler else { return info }
        
        let sessionSnapshot = sessionHandler.sessionSnapshot
        guard let sessionId = sessionSnapshot.sessionId else { return info }
        
        info["sessionId"] = sessionId
        
        if sessionSnapshot.isStart {
            info["sessionStart"] = true
            sessionHandler.updateSessionStart(isSessionStart: false)
        }
        
        guard sessionSnapshot.type == .automatic else { return info }
        
        // An event type the SDK does not own carries no recorded state, so the state in force now stands in for it.
        let createdInForeground = (event as? CreationStateCapturing)?.createdInForeground ?? sessionHandler.isInForeground
        if sessionHandler.shouldUpdateActivityTime(forEventCreatedInForeground: createdInForeground) {
            sessionHandler.updateSessionLastActivityTime()
        } else {
            analytics?.logger.debug(log: "SessionTrackingPlugin: Not updating activity time for event - the event was created in the background and background event updates are disabled.")
        }
        
        return info
    }
}
