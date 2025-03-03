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
    var sessionId: UInt64 = SessionConstants.defaultSessionId
    var sessionType: SessionType = SessionConstants.defaultSessionType
    var isSessionStart: Bool = SessionConstants.defaultIsSessionStart
    
    static func initializeState(_ storage: KeyValueStorage) -> SessionInfo {
        var state = SessionInfo()
        
        if let sessionIdValue: String = storage.read(key: Constants.StorageKeys.sessionId), let sessionId = UInt64(sessionIdValue) {
            state.sessionId = sessionId
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

// MARK: - Storage

extension SessionInfo {
    
    func storeSessionId(id: UInt64, storage: KeyValueStorage) {
        storage.write(value: String(id), key: Constants.StorageKeys.sessionId)
    }
    
    func storeIsSessionStart(isSessionStart: Bool, storage: KeyValueStorage) {
        storage.write(value: isSessionStart, key: Constants.StorageKeys.isSessionStart)
    }
    
    func storeSessionType(type: SessionType, storage: KeyValueStorage) {
        storage.write(value: type == .manual, key: Constants.StorageKeys.isManualSession)
    }
    
    func resetSessionState(storage: KeyValueStorage) {
        storage.remove(key: Constants.StorageKeys.sessionId)
        storage.remove(key: Constants.StorageKeys.isManualSession)
        storage.remove(key: Constants.StorageKeys.isSessionStart)
    }
}
