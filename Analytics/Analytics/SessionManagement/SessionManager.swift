//
//  SessionManager.swift
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

// MARK: - SessionManager
/**
 This class handles session management for both manual and automatic types.
 */
final class SessionManager {
    
    private var storage: KeyValueStorage
    private var sessionCofiguration: SessionConfiguration
    private var sessionState: StateImpl<SessionInfo>
    
    private var sessionInstance: SessionInfo {
        return self.sessionState.state.value
    }
    
    private var automaticSessionTimeout: Int {
        return self.sessionCofiguration.sessionTimeoutInMillis
    }
    
    init(storage: KeyValueStorage, sessionConfiguration: SessionConfiguration) {
        self.storage = storage
        self.sessionCofiguration = sessionConfiguration
        self.sessionState = createState(initialState: SessionInfo.initializeState(storage))
        
        self.prepareAutomaticSession()
    }
    
    func startSession(id: UInt64, type: SessionType = SessionConstants.defaultSessionType, shouldUpdateType: Bool = true) {
        self.updateSessionStart(isSessionStrat: true)
        if shouldUpdateType {
            self.updateSessionType(type: type)
        }
        self.updateSessionId(id: id)
    }
    
    func endSession() {
        self.sessionState.dispatch(action: EndSessionAction())
        self.sessionInstance.resetSessionState(storage: self.storage)
    }
    
    func refreshSession() {
        guard self.sessionId != SessionConstants.defaultSessionId else { return }
        self.startSession(id: SessionManager.generatedSessionId, shouldUpdateType: false)
    }
    
    func prepareAutomaticSession() {
        guard self.sessionCofiguration.automaticSessionTracking else { return }
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
