//
//  SessionState.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/02/25.
//

import Foundation

struct SessionState {
    var sessionId: UInt64 = SessionConstants.defaultSessionId
    var lastActivityTime: UInt64 = SessionConstants.defaultLastActivityTime
    var isManualSession: Bool = SessionConstants.defaultIsManualSession
    var isSessionStarted: Bool = SessionConstants.defaultIsSessionStarted
    
    static func initState(_ storage: KeyValueStorage) -> SessionState {
        var state = SessionState()
        
        if let sessionIdValue: String = storage.read(key: Constants.StorageKeys.sessionId), let sessionId = UInt64(sessionIdValue) {
            state.sessionId = sessionId
        }
        
        if let lastActivityTimeValue: String = storage.read(key: Constants.StorageKeys.lastActivityTime), let lastActivityTime = UInt64(lastActivityTimeValue) {
            state.lastActivityTime = lastActivityTime
        }
        
        if let isManualSession: Bool = storage.read(key: Constants.StorageKeys.isManualSession) {
            state.isManualSession = isManualSession
        }
        
        if let isSessionStarted: Bool = storage.read(key: Constants.StorageKeys.isSessionStarted) {
            state.isSessionStarted = isSessionStarted
        }
        
        return state
    }
}
