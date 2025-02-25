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

final class SessionManager {
    
    private var storage: Storage
    private var sessionState: StateImpl<SessionState>
    
    private var sessionInstance: SessionState {
        return self.sessionState.state.value
    }
    
    init(storage: Storage) {
        self.storage = storage
        self.sessionState = createState(initialState: SessionState.initState(storage))
    }
    
    func startSession(id: UInt64, type: SessionType, shouldUpdateType: Bool = true) {
        self.updateSesstionStart(isSessionStrat: true)
        if shouldUpdateType {
            self.updateSessionType(type: type)
        }
        self.updateSessionId(id: id)
    }
    
    func endSession() {
        /* temp implementation (no-op) */
    }
    
    var sessionId: UInt64? {
        return self.sessionInstance.sessionId == SessionConstants.defaultSessionId ? nil : self.sessionInstance.sessionId
    }
}

// MARK: - Helpers

extension SessionManager {
    
    static var generatedSessionId: UInt64 {
        return UInt64(Date().timeIntervalSince1970)
    }
    
    private func updateSessionId(id: UInt64) {
        self.sessionState.dispatch(action: UpdateSessionId(sessionId: id))
        self.sessionState.state.value.storeSessionType(type: .automatic, storage: self.storage)
    }
    
    private func updateSesstionStart(isSessionStrat: Bool) {
        guard self.sessionInstance.isSessionStart != isSessionStrat else { return }
        
        self.sessionState.dispatch(action: UpdateIsSessionStart(isSessionStart: isSessionStrat))
        self.sessionState.state.value.storeIsSessionStart(isSessionStart: isSessionStrat, storage: self.storage)
    }
    
    private func updateSessionType(type: SessionType) {
        guard self.sessionInstance.sessionType != type else { return }
        
        self.sessionState.dispatch(action: UpdateSessionType(sessionType: type))
        self.sessionState.state.value.storeSessionType(type: type, storage: self.storage)
    }
}

// MARK: - SessionConstants

struct SessionConstants {
    static let minSessionIdLength = 10
    static let defaultSessionId: UInt64 = 0
    static let defaultLastActivityTime: UInt64 = 0
    static let defaultSessionType: SessionType = .automatic
    static let defaultIsSessionStart: Bool = false
    
    private init() {
        /* Prevent instantiation (no-op) */
    }
}
