//
//  SessionInfoTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 26/02/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("SessionInfo Tests")
class SessionInfoTests {
    
    var mockStorage: KeyValueStorage
    var sessionInfo: SessionInfo
    
    init() {
        mockStorage = MockKeyValueStorageImpl()
        sessionInfo = SessionInfo.initializeState(mockStorage)
    }
    
    @Test("when storage is empty, then default values are used")
    func testInitializeStateWithEmptyStorage() {
        #expect(sessionInfo.id == SessionConstants.defaultSessionId)
        #expect(sessionInfo.isStart == SessionConstants.defaultIsSessionStart)
        #expect(sessionInfo.type == SessionConstants.defaultSessionType)
        #expect(sessionInfo.lastActivityTime == SessionConstants.defaultSessionLastActivityTime)
    }
    
    @Test("given invalid session id, when initialized, then default values are used")
    func testInitWithInvalidSessionId() {
        mockStorage.write(value: "invalid_number", key: Constants.storageKeys.sessionId)
        sessionInfo = SessionInfo.initializeState(mockStorage)
        
        #expect(sessionInfo.id == SessionConstants.defaultSessionId)
    }
    
    @Test("given invalid session last activity time, when initialized, then default values are used")
    func testInitWithInvalidLastActivityTime() {
        mockStorage.write(value: "invalid_time", key: Constants.storageKeys.lastActivityTime)
        sessionInfo = SessionInfo.initializeState(mockStorage)
        
        #expect(sessionInfo.lastActivityTime == SessionConstants.defaultSessionLastActivityTime)
    }

// MARK: - SessionInfo Storage Operations Tests

    @Test("given a session ID, when storing, then it is saved correctly", arguments: [
        (UInt64(1234567890), "1234567890"),
        (UInt64(0), "0"),
        (UInt64.max, String(UInt64.max))
    ])
    func testStoreSessionId(sessionId: UInt64, expectedString: String) {
        sessionInfo.storeSessionId(id: sessionId, storage: mockStorage)
        
        let storedValue: String? = mockStorage.read(key: Constants.storageKeys.sessionId)
        #expect(storedValue == expectedString)
    }

    @Test("given a session start flag, when storing, then it is saved correctly", arguments: [true, false])
    func testStoreIsSessionStart(isSessionStart: Bool) {
        sessionInfo.storeIsSessionStart(isSessionStart: isSessionStart, storage: mockStorage)
        
        let storedValue: Bool? = mockStorage.read(key: Constants.storageKeys.isSessionStart)
        #expect(storedValue == isSessionStart)
    }

    @Test("given a session type, when storing, then it is saved correctly", arguments: [
        (SessionType.manual, true),
        (SessionType.automatic, false)
    ])
    func testStoreSessionType(sessionType: SessionType, expectedBoolValue: Bool) {
        sessionInfo.storeSessionType(type: sessionType, storage: mockStorage)
        
        let storedValue: Bool? = mockStorage.read(key: Constants.storageKeys.isManualSession)
        #expect(storedValue == expectedBoolValue)
    }

    @Test("given a session activity time, when storing, then it is saved correctly", arguments: [
        UInt64(9876543210),
        UInt64(0),
        UInt64(Date().timeIntervalSince1970 * 1000)
    ])
    func testStoreSessionActivity(activityTime: UInt64) {
        sessionInfo.storeSessionActivity(time: activityTime, storage: mockStorage)
        
        let storedValue: String? = mockStorage.read(key: Constants.storageKeys.lastActivityTime)
        #expect(storedValue == String(activityTime))
    }

// MARK: - SessionInfo Integration Tests

    @Test("given a full session lifecycle stored, when retrieving, then data is consistent upon retrieval")
    func testFullSessionLifecycle() {
        
        let sessionId: UInt64 = 1234567890
        let isSessionStart = true
        let sessionType = SessionType.manual
        let activityTime: UInt64 = 9876543210
        
        sessionInfo.storeSessionId(id: sessionId, storage: mockStorage)
        sessionInfo.storeIsSessionStart(isSessionStart: isSessionStart, storage: mockStorage)
        sessionInfo.storeSessionType(type: sessionType, storage: mockStorage)
        sessionInfo.storeSessionActivity(time: activityTime, storage: mockStorage)
        
        let retrievedSessionInfo = SessionInfo.initializeState(mockStorage)
        
        #expect(retrievedSessionInfo.id == sessionId)
        #expect(retrievedSessionInfo.isStart == isSessionStart)
        #expect(retrievedSessionInfo.type == sessionType)
        #expect(retrievedSessionInfo.lastActivityTime == activityTime)
    }

    @Test("given proper session data, when overwrite occurs, then it replaces existing values")
    func testSessionDataOverwrite() {
        sessionInfo.storeSessionId(id: 1111111111, storage: mockStorage)
        sessionInfo.storeSessionType(type: .manual, storage: mockStorage)
        sessionInfo.storeIsSessionStart(isSessionStart: false, storage: mockStorage)
        
        let newSessionId: UInt64 = 2222222222
        let newSessionType = SessionType.automatic
        let newIsSessionStart = true
        
        sessionInfo.storeSessionId(id: newSessionId, storage: mockStorage)
        sessionInfo.storeSessionType(type: newSessionType, storage: mockStorage)
        sessionInfo.storeIsSessionStart(isSessionStart: newIsSessionStart, storage: mockStorage)
        
        let retrievedSessionInfo = SessionInfo.initializeState(mockStorage)
        
        #expect(retrievedSessionInfo.id == newSessionId)
        #expect(retrievedSessionInfo.type == newSessionType)
        #expect(retrievedSessionInfo.isStart == newIsSessionStart)
    }
}
