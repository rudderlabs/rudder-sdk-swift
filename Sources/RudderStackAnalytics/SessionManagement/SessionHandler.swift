//
//  SessionHandler.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

// MARK: - SessionType

enum SessionType {
    case manual
    case automatic
}

// MARK: - SessionHandler
/**
 This class handles session management for both manual and automatic types.
 */
final class SessionHandler {
    
    private var storage: KeyValueStorage
    private var sessionState: StateImpl<SessionInfo>
    private var sessionInstance: SessionInfo { self.sessionState.state.value }
    private var sessionCofiguration: SessionConfiguration { analytics.configuration.sessionConfiguration }
    private var automaticSessionTimeout: UInt64 { self.sessionCofiguration.sessionTimeoutInMillis }
    
    var analytics: Analytics
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.storage = analytics.configuration.storage
        self.sessionState = createState(initialState: SessionInfo.initializeState(storage))
        
        if sessionCofiguration.automaticSessionTracking {
            self.checkAndStartSessionOnLaunch()
            self.attachSessionTrackingObservers()
        } else if !isSessionManual {
            self.endSession()
        }
    }
    
    private func checkAndStartSessionOnLaunch() {
        guard self.sessionId == nil || self.isSessionManual || self.isSessionTimedOut else { return }
        self.startSession(id: Self.generatedSessionId, type: .automatic)
    }
    
    func startSession(id: UInt64, type: SessionType) {
        self.updateSessionStart(isSessionStart: true)
        self.updateSessionType(type: type)
        if isSessionManual {
            detachSessionTrackingObservers()
        }
        self.updateSessionId(id: id)
    }
    
    func endSession() {
        self.detachSessionTrackingObservers()
        
        self.sessionState.dispatch(action: EndSessionAction())
        self.sessionInstance.resetSessionState(storage: self.storage)
    }
    
    func refreshSession() {
        guard let currentSessionId = self.sessionId, currentSessionId != SessionConstants.defaultSessionId else { return }
        self.startSession(id: SessionHandler.generatedSessionId, type: self.sessionType)
    }
    
    deinit {
        self.detachSessionTrackingObservers()
    }
}

// MARK: - Observers
extension SessionHandler: LifecycleEventListener {
    
    func attachSessionTrackingObservers() {
        self.analytics.lifecycleObserver?.addObserver(self)
    }
    
    func detachSessionTrackingObservers() {
        self.analytics.lifecycleObserver?.removeObserver(self)
    }
    
    // MARK: - Lifecycle Event Handlers
    
    func onBackground() {
        self.updateSessionLastActivityTime()
    }
    
    func onForeground() {
        guard self.sessionId != nil, self.sessionType == .automatic, self.isSessionTimedOut else { return }
        self.startSession(id: Self.generatedSessionId, type: .automatic)
    }
    
    func onTerminate() {
        self.updateSessionLastActivityTime()
    }
}

// MARK: - Helpers

extension SessionHandler {
    
    static var generatedSessionId: UInt64 {
        return UInt64(Date().timeIntervalSince1970)
    }
    
    var sessionId: UInt64? {
        return self.sessionInstance.id == SessionConstants.defaultSessionId ? nil : self.sessionInstance.id
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
    
    var monotonicCurrentTime: UInt64 {
        let millisecondsInSecond: TimeInterval = 1000.0
        return UInt64(ProcessInfo.processInfo.systemUptime * millisecondsInSecond)
    }
    
    var isSessionTimedOut: Bool {
        let timeDifference = self.monotonicCurrentTime &- self.lastActivityTime // Safe subtraction
        return timeDifference > self.automaticSessionTimeout
    }
}

// MARK: - Session Action Handlers

extension SessionHandler {
    
    private func updateSessionId(id: UInt64) {
        self.sessionState.dispatch(action: UpdateSessionIdAction(sessionId: id))
        self.sessionInstance.storeSessionId(id: id, storage: self.storage)
    }
    
    func updateSessionStart(isSessionStart: Bool) {
        guard self.sessionInstance.isStart != isSessionStart else { return }
        
        self.sessionState.dispatch(action: UpdateIsSessionStartAction(isSessionStart: isSessionStart))
        self.sessionInstance.storeIsSessionStart(isSessionStart: isSessionStart, storage: self.storage)
    }
    
    private func updateSessionType(type: SessionType) {
        guard self.sessionInstance.type != type else { return }
        
        self.sessionState.dispatch(action: UpdateSessionTypeAction(sessionType: type))
        self.sessionInstance.storeSessionType(type: type, storage: self.storage)
    }
    
    func updateSessionLastActivityTime(_ time: UInt64? = nil) {
        let lastActivityTime = time ?? self.monotonicCurrentTime
        self.sessionState.dispatch(action: UpdateSessionLastActivityAction(lastActivityTime: lastActivityTime))
        self.sessionInstance.storeSessionActivity(time: lastActivityTime, storage: self.storage)
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
