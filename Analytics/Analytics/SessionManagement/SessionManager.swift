//
//  SessionManager.swift
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

// MARK: - SessionManager
/**
 This class handles session management for both manual and automatic types.
 */
final class SessionManager {
    
    private var storage: KeyValueStorage
    private var sessionCofiguration: SessionConfiguration
    private var sessionState: StateImpl<SessionInfo>
    
    private var sessionInstance: SessionInfo { self.sessionState.state.value }
    private var automaticSessionTimeout: UInt64 { self.sessionCofiguration.sessionTimeoutInMillis }
    
    var backgroundObserver: NSObjectProtocol?
    var foregroundObserver: NSObjectProtocol?
    var terminateObserver: NSObjectProtocol?
    
    init(storage: KeyValueStorage, sessionConfiguration: SessionConfiguration) {
        self.storage = storage
        self.sessionCofiguration = sessionConfiguration
        self.sessionState = createState(initialState: SessionInfo.initializeState(storage))
        
        self.ensureAutomaticSession()
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
        guard self.sessionId != SessionConstants.defaultSessionId else { return }
        self.startSession(id: SessionManager.generatedSessionId, type: self.sessionType)
    }
    
    func ensureAutomaticSession() {
        guard self.sessionCofiguration.automaticSessionTracking else { return }
        if self.sessionId == nil || self.sessionType == .manual || self.isSessionTimedOut {
            self.startSession(id: Self.generatedSessionId, type: .automatic)
        }
    }
    
    deinit {
        self.detachObservers()
    }
}

// MARK: - Observers

extension SessionManager {
    
    func attachObservers() {
        self.detachObservers()  // Prevent duplicate observers
        
#if os(macOS)
        // macOS (AppKit)
        let backgroundNotification = NSApplication.didResignActiveNotification
        let terminateNotification = NSApplication.willTerminateNotification
        let foregroundNotification = NSApplication.didBecomeActiveNotification
#else
        // iOS, tvOS, watchOS, and Mac Catalyst (UIKit)
        let backgroundNotification = UIApplication.didEnterBackgroundNotification
        let terminateNotification = UIApplication.willTerminateNotification
        let foregroundNotification = UIApplication.willEnterForegroundNotification
#endif
        
        let handleBackground: (Notification) -> Void = { [weak self] _ in
            self?.updateSessionLastActivityTime()
        }
        
        let handleForeground: (Notification) -> Void = { [weak self] _ in
            guard let self = self, self.sessionId != nil, self.sessionType == .automatic, self.isSessionTimedOut else { return }
            self.startSession(id: Self.generatedSessionId, type: .automatic)
        }
        
        let notificationCenter = NotificationCenter.default
        self.backgroundObserver = notificationCenter.addObserver(forName: backgroundNotification, object: nil, queue: .main, using: handleBackground)
        self.foregroundObserver = notificationCenter.addObserver(forName: foregroundNotification, object: nil, queue: .main, using: handleForeground)
        self.terminateObserver = notificationCenter.addObserver(forName: terminateNotification, object: nil, queue: .main, using: handleBackground)
    }
    
    func detachObservers() {
        [backgroundObserver, foregroundObserver, terminateObserver].compactMap { $0 }.forEach { NotificationCenter.default.removeObserver($0) }
        backgroundObserver = nil
        foregroundObserver = nil
        terminateObserver = nil
    }
}

// MARK: - Helpers

extension SessionManager {
    
    static var generatedSessionId: UInt64 {
        return UInt64(Date().timeIntervalSince1970)
    }
    
    var sessionId: UInt64? {
        return self.sessionInstance.sessionId == SessionConstants.defaultSessionId ? nil : self.sessionInstance.sessionId
    }
    
    var isSessionStart: Bool {
        return self.sessionInstance.isSessionStart
    }
    
    var sessionType: SessionType {
        return self.sessionInstance.sessionType
    }
    
    var lastActivityTime: UInt64 {
        return self.sessionInstance.lastActivityTime
    }
    
    var monotonicCurrentTime: UInt64 {
        let millisecondsInSecond: TimeInterval = 1000.0
        return UInt64(ProcessInfo.processInfo.systemUptime * millisecondsInSecond)
    }
    
    var isSessionTimedOut: Bool {
        return (self.monotonicCurrentTime - self.lastActivityTime) > self.automaticSessionTimeout
    }
}

// MARK: - Session Action Handlers

extension SessionManager {
    
    private func updateSessionId(id: UInt64) {
        self.sessionState.dispatch(action: UpdateSessionIdAction(sessionId: id))
        self.sessionInstance.storeSessionId(id: id, storage: self.storage)
    }
    
    func updateSessionStart(isSessionStrat: Bool) {
        guard self.sessionInstance.isSessionStart != isSessionStrat else { return }
        
        self.sessionState.dispatch(action: UpdateIsSessionStartAction(isSessionStart: isSessionStrat))
        self.sessionInstance.storeIsSessionStart(isSessionStart: isSessionStrat, storage: self.storage)
    }
    
    private func updateSessionType(type: SessionType) {
        guard self.sessionInstance.sessionType != type else { return }
        
        self.sessionState.dispatch(action: UpdateSessionTypeAction(sessionType: type))
        self.sessionInstance.storeSessionType(type: type, storage: self.storage)
    }
    
    func updateSessionLastActivityTime() {
        let lastActivityTime = self.monotonicCurrentTime
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
