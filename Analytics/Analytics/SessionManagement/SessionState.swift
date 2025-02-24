//
//  SessionState.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/02/25.
//

import Foundation

struct SessionState {
    var sessionId: Int64 = 0
    var lastActivityTime: Int64 = 0
    var isManualSession: Bool = false
    var isSessionStarted: Bool = false
        
    static func initState(_ storage: KeyValueStorage) -> SessionState {
        var state = SessionState()
        
        state.sessionId = storage.read(key: Constants.StorageKeys.sessionId) ?? 0
        state.lastActivityTime = storage.read(key: Constants.StorageKeys.lastActivityTime) ?? 0
        state.isManualSession = storage.read(key: Constants.StorageKeys.isManualSession) ?? false
        state.isSessionStarted = storage.read(key: Constants.StorageKeys.isSessionStarted) ?? false
        
        return state
    }
}
