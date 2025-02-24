//
//  SessionManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

final class SessionManager {
    
    private var storage: Storage
    private var sessionState: StateImpl<SessionState>
    
    private var sessionInstance: SessionState {
        return self.sessionState.state.value
    }
    
    init (storage: Storage) {
        self.storage = storage
        self.sessionState = createState(initialState: SessionState.initState(storage))
    }
    
    func startSession(sessionId: Int64, isManualSession: Bool) {
        
    }
    
    func endSession() {
        
    }
    
    var sessionId: Int64? {
        return self.sessionInstance.sessionId == SessionConstants.defaultSessionId ? nil : self.sessionInstance.sessionId
    }
}

extension SessionManager {
    
    static var generatedSessionId: Int64 {
        return Int64(Date().timeIntervalSince1970)
    }
    
    private func withSessionDispatcher(_ block: @escaping () async -> Void) {
        Task { await block() }
    }
}


struct SessionConstants {
    static let minSessionIdLength = 10
    static let defaultSessionId: Int64 = 0
    static let defaultLastActivityTime: Int64 = 0
    static let defaultIsManualSession: Bool = false
    static let defaultIsSessionStarted: Bool = false
    
    private init() {
        /* Prevent instantiation (no-op) */
    }
}
