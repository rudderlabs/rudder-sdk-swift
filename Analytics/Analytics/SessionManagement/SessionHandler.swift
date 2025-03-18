//
//  SessionHandler.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
    
    var analytics: AnalyticsClient
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.storage = analytics.configuration.storage
        self.sessionState = createState(initialState: SessionInfo.initializeState(storage))
    }
    
    func startSession(id: UInt64, type: SessionType) {
        self.updateSessionStart(isSessionStrat: true)
        self.updateSessionType(type: type)
        self.updateSessionId(id: id)
        self.sessionType == .automatic ? self.attachObservers() : self.detachObservers()
    }
    
    func endSession() {
        self.sessionState.dispatch(action: EndSessionAction())
        self.sessionInstance.resetSessionState(storage: self.storage)
        self.detachObservers()
    }
    
    func refreshSession() {
        guard let currentSessionId = self.sessionId, currentSessionId != SessionConstants.defaultSessionId else { return }
        self.startSession(id: SessionHandler.generatedSessionId, type: self.sessionType)
    }
    
    func startAutomaticSessionIfNeeded() {
        if self.sessionCofiguration.automaticSessionTracking {
            if self.sessionId == nil || self.sessionType == .manual || self.isSessionTimedOut {
                self.startSession(id: Self.generatedSessionId, type: .automatic)
            }
        } else if self.sessionId != nil, self.sessionType == .automatic {
            self.endSession()
        }
    }
    
    deinit {
        self.detachObservers()
    }
}

// MARK: - Observers
extension SessionHandler: LifecycleEventListener {
    
    func attachObservers() {
        self.analytics.lifecycleObserver?.addObserver(self)
    }
    
    func detachObservers() {
        self.analytics.lifecycleObserver?.removeObserver(self)
    }
    
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
    
    func updateSessionStart(isSessionStrat: Bool) {
        guard self.sessionInstance.isStart != isSessionStrat else { return }
        
        self.sessionState.dispatch(action: UpdateIsSessionStartAction(isSessionStart: isSessionStrat))
        self.sessionInstance.storeIsSessionStart(isSessionStart: isSessionStrat, storage: self.storage)
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
