//
//  SessionActions.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/02/25.
//

import Foundation

// MARK: - UpdateSessionIdAction

struct UpdateSessionIdAction: StateAction {
    typealias T = SessionState
    
    private let sessionId: UInt64
    
    init(sessionId: UInt64) {
        self.sessionId = sessionId
    }
    
    func reduce(currentState: SessionState) -> SessionState {
        var updatedState = currentState
        updatedState.sessionId = sessionId
        return updatedState
    }
}

// MARK: - UpdateIsSessionStartAction

struct UpdateIsSessionStartAction: StateAction {
    typealias T = SessionState
    
    private let isSessionStart: Bool
    
    init(isSessionStart: Bool) {
        self.isSessionStart = isSessionStart
    }
    
    func reduce(currentState: SessionState) -> SessionState {
        var updatedState = currentState
        updatedState.isSessionStart = isSessionStart
        return updatedState
    }
}

// MARK: - UpdateSessionTypeAction

struct UpdateSessionTypeAction: StateAction {
    typealias T = SessionState
    
    private let sessionType: SessionType
    
    init(sessionType: SessionType) {
        self.sessionType = sessionType
    }
    
    func reduce(currentState: SessionState) -> SessionState {
        var updatedState = currentState
        updatedState.sessionType = sessionType
        return updatedState
    }
}

// MARK: - EndSessionAction

struct EndSessionAction: StateAction {
    typealias T = SessionState
    
    func reduce(currentState: SessionState) -> SessionState {
        return SessionState(sessionId: SessionConstants.defaultSessionId,
                            sessionType: SessionConstants.defaultSessionType,
                            isSessionStart: SessionConstants.defaultIsSessionStart)
    }
}
