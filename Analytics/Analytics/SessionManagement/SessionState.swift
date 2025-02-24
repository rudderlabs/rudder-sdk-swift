//
//  SessionState.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/02/25.
//

import Foundation

struct SessionState {
    var sessionId: UInt64 = 0
    var lastActivityTime: UInt64 = 0
    var isManualSession: Bool = false
    var isSessionStarted: Bool = false
        
    static func initState(_ storage: KeyValueStorage) -> SessionState {
        var state = SessionState()
        
        state.sessionId = storage.read(key: Constants.StorageKeys.sessionId) ?? SessionConstants.defaultSessionId
        state.lastActivityTime = storage.read(key: Constants.StorageKeys.lastActivityTime) ?? SessionConstants.defaultLastActivityTime
        state.isManualSession = storage.read(key: Constants.StorageKeys.isManualSession) ?? SessionConstants.defaultIsManualSession
        state.isSessionStarted = storage.read(key: Constants.StorageKeys.isSessionStarted) ?? SessionConstants.defaultIsSessionStarted
        
        return state
    }
}
