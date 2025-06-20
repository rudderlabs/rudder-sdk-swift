//
//  SessionInfo.swift
//  Analytics
//
//  Created by Satheesh Kannan on 24/02/25.
//

import Foundation

// MARK: - SessionInfo
/**
 A struct encapsulates session-related information.
 */
struct SessionInfo {
    var id: UInt64 = SessionConstants.defaultSessionId
    var type: SessionType = SessionConstants.defaultSessionType
    var isStart: Bool = SessionConstants.defaultIsSessionStart
    var lastActivityTime: UInt64 = SessionConstants.defaultSessionLastActivityTime
    
    static func initializeState(_ storage: KeyValueStorage) -> SessionInfo {
        var state = SessionInfo()
        
        if let sessionIdValue: String = storage.read(key: Constants.storageKeys.sessionId), let sessionId = UInt64(sessionIdValue) {
            state.id = sessionId
        }
        
        if let isManualSession: Bool = storage.read(key: Constants.storageKeys.isManualSession) {
            state.type = isManualSession ? .manual : .automatic
        }
        
        if let isSessionStart: Bool = storage.read(key: Constants.storageKeys.isSessionStart) {
            state.isStart = isSessionStart
        }
        
        if let lastActivityTimeValue: String = storage.read(key: Constants.storageKeys.lastActivityTime), let lastActivityTime = UInt64(lastActivityTimeValue) {
            state.lastActivityTime = lastActivityTime
        }
      
        return state
    }
}

// MARK: - Storage

extension SessionInfo {
    
    func storeSessionId(id: UInt64, storage: KeyValueStorage) {
        storage.write(value: String(id), key: Constants.storageKeys.sessionId)
    }
    
    func storeIsSessionStart(isSessionStart: Bool, storage: KeyValueStorage) {
        storage.write(value: isSessionStart, key: Constants.storageKeys.isSessionStart)
    }
    
    func storeSessionType(type: SessionType, storage: KeyValueStorage) {
        storage.write(value: type == .manual, key: Constants.storageKeys.isManualSession)
    }
    
    func storeSessionActivity(time: UInt64, storage: KeyValueStorage) {
        storage.write(value: String(time), key: Constants.storageKeys.lastActivityTime)
    }
    
    func resetSessionState(storage: KeyValueStorage) {
        storage.remove(key: Constants.storageKeys.sessionId)
        storage.remove(key: Constants.storageKeys.isManualSession)
        storage.remove(key: Constants.storageKeys.isSessionStart)
        storage.remove(key: Constants.storageKeys.lastActivityTime)
    }
}
