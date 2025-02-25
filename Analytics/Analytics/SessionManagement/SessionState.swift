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
    var sessionType: SessionType = SessionConstants.defaultSessionType
    var isSessionStart: Bool = SessionConstants.defaultIsSessionStart
    
    static func initState(_ storage: KeyValueStorage) -> SessionState {
        var state = SessionState()
        
        if let sessionIdValue: String = storage.read(key: Constants.StorageKeys.sessionId), let sessionId = UInt64(sessionIdValue) {
            state.sessionId = sessionId
        }
        
        if let lastActivityTimeValue: String = storage.read(key: Constants.StorageKeys.lastActivityTime), let lastActivityTime = UInt64(lastActivityTimeValue) {
            state.lastActivityTime = lastActivityTime
        }
        
        if let isManualSession: Bool = storage.read(key: Constants.StorageKeys.isManualSession) {
            state.sessionType = isManualSession ? .manual : .automatic
        }
        
        if let isSessionStart: Bool = storage.read(key: Constants.StorageKeys.isSessionStart) {
            state.isSessionStart = isSessionStart
        }
        
        return state
    }
}

extension SessionState {
    
    func storeSessionId(id: UInt64, storage: KeyValueStorage) {
        storage.write(value: String(id), key: Constants.StorageKeys.sessionId)
    }
    
    func storeIsSessionStart(isSessionStart: Bool, storage: KeyValueStorage) {
        storage.write(value: isSessionStart, key: Constants.StorageKeys.isSessionStart)
    }
    
    func storeSessionType(type: SessionType, storage: KeyValueStorage) {
        storage.write(value: type == .manual, key: Constants.StorageKeys.sessionId)
    }
}
