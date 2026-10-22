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
        guard let sessionHandler = self.analytics?.sessionHandler else { return event }
        
        // An event type the SDK does not own carries no recorded state, so the state in force now stands in for it.
        let createdInForeground = (event as? CreationStateCapturing)?.createdInForeground ?? sessionHandler.isInForeground
        let sessionInfo = sessionHandler.withSessionLock {
            self.sessionInfo(for: event, createdInForeground: createdInForeground, sessionHandler: sessionHandler)
        }
        return event.addToContext(info: sessionInfo)
    }
    
    private func sessionInfo(for event: any Event, createdInForeground: Bool, sessionHandler: SessionHandler) -> [String: Any] {
        if !createdInForeground {
            sessionHandler.startSessionOnBackgroundEventIfNeeded()
        }
        guard let sessionId = sessionHandler.sessionId else { return [:] }
        
        let countsAsUserActivity = sessionHandler.countsAsUserActivity(createdInForeground: createdInForeground)
        // SDK lifecycle events keep their session in the background, so a session stays measurable.
        guard sessionHandler.isSessionManual || countsAsUserActivity || event.isLifecycleEvent else {
            analytics?.logger.debug(log: "SessionTrackingPlugin: Skipping session data for a background event (messageId=\(event.messageId))")
            return [:]
        }
        
        var info: [String: Any] = ["sessionId": sessionId]
        if sessionHandler.isSessionStart {
            info["sessionStart"] = true
            sessionHandler.updateSessionStart(isSessionStart: false)
        }
        
        // The SDK never extends a manual session.
        if !sessionHandler.isSessionManual && countsAsUserActivity {
            sessionHandler.updateSessionLastActivityTime()
        }
        return info
    }
}

private extension Event {
    /// Matched by name, so an app event with the same name also counts.
    var isLifecycleEvent: Bool {
        guard let trackEvent = self as? TrackEvent else { return false }
        return LifecycleEvent(rawValue: trackEvent.event) != nil
    }
}
