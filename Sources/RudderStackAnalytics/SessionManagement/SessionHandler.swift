//
//  SessionHandler.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

// MARK: - SessionType

enum SessionType: Equatable {
    case manual
    case automatic
}

// MARK: - SessionHandler
/**
 This class handles session management for both manual and automatic types.

 An automatic session starts on the first foreground of a process, never when the SDK starts. The system can
 start a process with no screen, and such a start must not open a session that the user did not begin.
 */
final class SessionHandler: TypeIdentifiable {
    
    private var storage: KeyValueStorage
    private var sessionState: StateImpl<SessionInfo>
    private var sessionInstance: SessionInfo { self.sessionState.value }
    private var sessionConfiguration: SessionConfiguration { analytics.configuration.sessionConfiguration }
    private var automaticSessionTimeout: UInt64 { self.sessionConfiguration.sessionTimeoutInMillis }
    
    // The app, the lifecycle callbacks and the event pipeline change the session from different threads.
    private let sessionLock = NSRecursiveLock()
    // The first foreground of a process applies the launch rules. Guarded by `sessionLock`.
    private var isFirstForegroundPending = true
    // Guarded by `sessionLock`.
    private var isAutomaticTrackingActive = false
    
    var analytics: Analytics
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.storage = analytics.configuration.storage
        self.sessionState = createState(initialState: SessionInfo.initializeState(storage))
        
        if sessionConfiguration.automaticSessionTracking {
            // A manual session left by an earlier process is over; an automatic one starts on the first foreground.
            if isSessionManual {
                self.clearSession()
            }
            self.attachSessionTrackingObservers()
        } else if !isSessionManual {
            analytics.logger.debug(log: "\(className): Ending session — both manual and automatic session tracking is disabled")
            self.endSession()
        }
    }

    func startSession(id: UInt64, type: SessionType) {
        withSessionLock {
            analytics.logger.debug(log: "\(className): Starting \(type == .manual ? "manual" : "automatic") session (id=\(id))")
            self.sessionState.dispatch(action: StartSessionAction(sessionId: id, sessionType: type))

            self.sessionInstance.storeSessionId(id: id, storage: self.storage)
            self.sessionInstance.storeIsSessionStart(isSessionStart: true, storage: self.storage)
            self.sessionInstance.storeSessionType(type: type, storage: self.storage)

            if type == .manual {
                detachSessionTrackingObservers()
            }
            // A new session is active from its start; an old time would make the next foreground start another one.
            self.updateSessionLastActivityTime()
        }
    }

    func endSession() {
        withSessionLock {
            self.detachSessionTrackingObservers()
            self.clearSession()
            analytics.logger.debug(log: "\(className): Session ended")
        }
    }
    
    func refreshSession() {
        withSessionLock {
            guard self.sessionId != nil else { return }
            self.startSession(id: Self.generatedSessionId, type: self.sessionType)
        }
    }

    /// Runs several session steps as one unit, so no other thread changes the session midway.
    func withSessionLock<T>(_ block: () -> T) -> T {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return block()
    }
    
    private func clearSession() {
        self.sessionState.dispatch(action: EndSessionAction())
        self.sessionInstance.resetSessionState(storage: self.storage)
    }
    
    deinit {
        self.analytics.lifecycleObserver?.removeObserver(self)
    }
}

// MARK: - Automatic Session Rules

extension SessionHandler {
    
    /// The first foreground applies the launch rules; every later one only replaces a timed-out session.
    private func startSessionOnForegroundIfNeeded() {
        withSessionLock {
            // A callback already in flight when the app ended or took over the session must not start one.
            guard isAutomaticTrackingActive else { return }
            
            let isFirstForeground = isFirstForegroundPending
            isFirstForegroundPending = false
            
            let needsNewSession = isFirstForeground ? !hasLiveAutomaticSession : hasTimedOutAutomaticSession
            if needsNewSession {
                self.startSession(id: Self.generatedSessionId, type: .automatic)
            }
        }
    }
    
    /// With background events included, a background event starts a new session when no live one exists.
    func startSessionOnBackgroundEventIfNeeded() {
        guard sessionConfiguration.includeBackgroundEventsInSession else { return }
        
        withSessionLock {
            guard isAutomaticTrackingActive, !hasLiveAutomaticSession else { return }
            self.startSession(id: Self.generatedSessionId, type: .automatic)
        }
    }
    
    /// Whether an event counts as user activity: it then carries the automatic session and extends it.
    func countsAsUserActivity(createdInForeground: Bool) -> Bool {
        return sessionConfiguration.includeBackgroundEventsInSession || createdInForeground
    }
    
    /// The session ID that an event sent now would carry.
    var visibleSessionId: UInt64? {
        withSessionLock {
            guard let sessionId = self.sessionId else { return nil }
            if isSessionManual { return sessionId }
            
            let isInForeground = self.isInForeground
            guard countsAsUserActivity(createdInForeground: isInForeground) else { return nil }
            // The next background event replaces a timed-out session, so it is no longer the current one.
            if !isInForeground && isSessionTimedOut { return nil }
            return sessionId
        }
    }
    
    private var hasLiveAutomaticSession: Bool {
        return self.sessionId != nil && !isSessionManual && !isSessionTimedOut
    }
    
    private var hasTimedOutAutomaticSession: Bool {
        return self.sessionId != nil && !isSessionManual && isSessionTimedOut
    }
}

// MARK: - Observers
extension SessionHandler: LifecycleEventListener {
    
    private func attachSessionTrackingObservers() {
        withSessionLock { isAutomaticTrackingActive = true }
        self.analytics.lifecycleObserver?.addObserver(self)
    }
    
    private func detachSessionTrackingObservers() {
        withSessionLock { isAutomaticTrackingActive = false }
        self.analytics.lifecycleObserver?.removeObserver(self)
    }
    
    // MARK: - Lifecycle Event Handlers
    
    func onBackground() {
        self.updateSessionLastActivityTime()
    }
    
    func onForeground() {
        self.startSessionOnForegroundIfNeeded()
    }
    
    func onTerminate() {
        // Time in the background is not activity, so only an app that ends in the foreground records it.
        guard isInForeground else { return }
        self.updateSessionLastActivityTime()
    }
}

// MARK: - Helpers

extension SessionHandler {
    
    static var generatedSessionId: UInt64 {
        return UInt64(Date().timeIntervalSince1970)
    }
    
    var isInForeground: Bool {
        return self.analytics.lifecycleObserver?.isInForeground ?? false
    }
    
    var sessionId: UInt64? {
        return self.sessionInstance.sessionId
    }
    
    var isSessionStart: Bool {
        return self.sessionInstance.isStart
    }
    
    var isSessionManual: Bool {
        return self.sessionInstance.type == .manual
    }
    
    var sessionType: SessionType {
        return self.sessionInstance.type
    }
    
    var lastActivityTime: UInt64 {
        return self.sessionInstance.lastActivityTime
    }
    
    var systemCurrentTime: UInt64 {
        let millisecondsInSecond: TimeInterval = 1000.0
        let interval = Date().timeIntervalSince1970
        return interval > 0 ? UInt64(interval * millisecondsInSecond) : 0
    }
    
    /**
     Determines if the current session has timed out.
     
     A session is considered timed out if the elapsed time since the last recorded
     activity exceeds the configured session timeout.
     
     This method uses system current time. If the current system time is earlier than the last activity time,
     it indicates that the clock has been tampered with. In such cases, the session is treated as expired.
     Zero elapsed time does not count as expired, so two events in the same millisecond stay in one session.
     
     - Returns: `true` if the session has timed out, `false` otherwise.
     */
    var isSessionTimedOut: Bool {
        let currentTime = self.systemCurrentTime
        let lastActivityTime = self.lastActivityTime
        
        if currentTime < lastActivityTime {
            analytics.logger.warn(log: "\(className): Current system time is earlier than the last activity time." +
                " This indicates potential clock tampering. Resetting the session")
            return true
        }
        
        return currentTime - lastActivityTime > self.automaticSessionTimeout
    }
}

// MARK: - Session Action Handlers

extension SessionHandler {
    
    func updateSessionStart(isSessionStart: Bool) {
        withSessionLock {
            guard self.sessionInstance.isStart != isSessionStart else { return }
            
            self.sessionState.dispatch(action: UpdateIsSessionStartAction(isSessionStart: isSessionStart))
            self.sessionInstance.storeIsSessionStart(isSessionStart: isSessionStart, storage: self.storage)
        }
    }
    
    func updateSessionLastActivityTime(_ time: UInt64? = nil) {
        withSessionLock {
            let lastActivityTime = time ?? self.systemCurrentTime
            self.sessionState.dispatch(action: UpdateSessionLastActivityAction(lastActivityTime: lastActivityTime))
            self.sessionInstance.storeSessionActivity(time: lastActivityTime, storage: self.storage)
        }
    }
}

// MARK: - SessionConstants

struct SessionConstants {
    static let minSessionIdLength = 10
    static let defaultSessionId: UInt64 = 0
    static let defaultSessionLastActivityTime: UInt64 = 0
    static let defaultSessionType: SessionType = .automatic
    static let defaultIsSessionStart: Bool = false
    
    private init() {
        /* Prevent instantiation (no-op) */
    }
}
