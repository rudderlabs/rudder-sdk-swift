//
//  SessionHandlerTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("SessionHandler Tests")
struct SessionHandlerTests {
    
    // MARK: - Initialization Tests
    
    @Test("given a session configuration with automatic tracking enabled, when initializing the session handler, then it should have a session ID and isSessionStart set correctly", arguments: [
        SessionConfiguration(automaticSessionTracking: true),
        SessionConfiguration(automaticSessionTracking: false)
    ])
    func testSessionHandlerInitialization(configuration: SessionConfiguration) {
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        switch configuration.automaticSessionTracking {
        case true:
            #expect(sessionHandler.sessionId != nil)
            #expect(sessionHandler.isSessionStart != SessionConstants.defaultIsSessionStart)
        case false:
            #expect(sessionHandler.sessionId == nil)
            #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
        }
    }
    
    @Test("given existing session data in storage, when initializing the session handler, then it should load the session data correctly")
    func testInitializationWithExistingData() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        storage.write(value: "1234567890", key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isSessionStart)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        storage.write(value: "9876543210", key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId == 1234567890)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
        #expect(sessionHandler.lastActivityTime == 9876543210)
    }
    
    // MARK: - Session Management Tests

    @Test("given a session configuration with automatic tracking enabled, when starting a session, then it should set the session ID and type correctly", arguments: [
        SessionHandlerTestCase(sessionId: 1234567890, sessionType: .manual, description: "manual session"),
        SessionHandlerTestCase(sessionId: 9876543210, sessionType: .automatic, description: "automatic session"),
        SessionHandlerTestCase(sessionId: UInt64.max, sessionType: .automatic, description: "maximum session ID")
    ])
    func testStartSession(testCase: SessionHandlerTestCase) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: testCase.sessionId, type: testCase.sessionType)
        
        #expect(sessionHandler.sessionId == testCase.sessionId)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == testCase.sessionType)
    }
    
    @Test("given a session configuration with automatic tracking enabled, when starting a session, then it should set the session ID and type correctly")
    func testStartSessionWithZeroId() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: 0, type: .manual)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given a session configuration with automatic tracking enabled, when ending a session, then it should reset the session state")
    func testEndSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: 1234567890, type: .manual)
        sessionHandler.endSession()
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
        #expect(sessionHandler.sessionType == SessionConstants.defaultSessionType)
    }

    @Test("given a session configuration with automatic tracking enabled, when refreshing a session, then it should update the session ID and type correctly", arguments: [
        (true, "with active session"),
        (false, "without active session")
    ])
    func testRefreshSession(hasActiveSession: Bool, description: String) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        var originalSessionId: UInt64?
        
        if hasActiveSession {
            originalSessionId = 1234567890
            sessionHandler.startSession(id: originalSessionId!, type: .manual)
        }
        
        sessionHandler.refreshSession()
        
        switch hasActiveSession {
        case true:
            #expect(sessionHandler.sessionId != originalSessionId, "Session ID should be refreshed")
            #expect(sessionHandler.sessionId != nil, "Session ID should not be nil after refresh")
            #expect(sessionHandler.isSessionStart, "Session should be marked as started")
            #expect(sessionHandler.sessionType == .manual, "Session type should remain manual")
        case false:
            #expect(sessionHandler.sessionId == nil, "Session ID should remain nil when no active session exists")
        }
    }
    
    // MARK: - Automatic Session Tests

    @Test("given a session configuration with automatic tracking enabled, when starting a session, then it should set the session ID and type correctly", arguments: [
        (true, nil, "start automatic when tracking enabled"),
        (true, SessionType.manual, "replace manual with automatic"),
        (false, SessionType.automatic, "end automatic when tracking disabled"),
        (false, SessionType.manual, "keep manual when tracking disabled")
    ])
    func testAutomaticSessionManagement(trackingEnabled: Bool, existingSessionType: SessionType?, description: String) {
        let configuration = SessionConfiguration(automaticSessionTracking: trackingEnabled)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        var originalSessionId: UInt64?
        if let sessionType = existingSessionType {
            originalSessionId = 1111111111
            sessionHandler.startSession(id: originalSessionId!, type: sessionType)
        }
        
        sessionHandler.startAutomaticSessionIfNeeded()
        
        if trackingEnabled {
            if existingSessionType == .manual || existingSessionType == nil {
                #expect(sessionHandler.sessionId != originalSessionId)
                #expect(sessionHandler.sessionType == .automatic)
            }
        } else {
            if existingSessionType == .automatic {
                #expect(sessionHandler.sessionId == nil)
            } else if existingSessionType == .manual {
                #expect(sessionHandler.sessionId == originalSessionId)
                #expect(sessionHandler.sessionType == .manual)
            }
        }
    }
    
    // MARK: - Timeout and State Management Tests

    @Test("given a session configuration with automatic tracking enabled, when testing session timeout, then it should correctly identify timeout states", arguments: [
        (5000, 6000, true, "session timed out"),
        (10000, 5000, false, "session not timed out"),
        (5000, 5000, false, "session at timeout boundary")
    ])
    func testSessionTimeout(timeoutMs: UInt64, timeDifferenceMs: UInt64, expectedTimedOut: Bool, description: String) {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: timeoutMs)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        let pastTime = sessionHandler.monotonicCurrentTime - timeDifferenceMs
        sessionHandler.updateSessionLastActivityTime(pastTime)
        
        #expect(sessionHandler.isSessionTimedOut == expectedTimedOut)
    }

    @Test("given a session configuration with automatic tracking enabled, when updating the session start flag, then it should set the session start state correctly", arguments: [true, false])
    func testUpdateSessionStart(isSessionStart: Bool) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.updateSessionStart(isSessionStart: isSessionStart)
        
        #expect(sessionHandler.isSessionStart == isSessionStart)
    }

    @Test("given a session configuration with automatic tracking enabled, when updating the session activity time, then it should set the last activity time correctly")
    func testUpdateSessionActivityTime() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        let testTime: UInt64 = 1234567890
        let beforeTime = sessionHandler.monotonicCurrentTime
        
        sessionHandler.updateSessionLastActivityTime(testTime)
        #expect(sessionHandler.lastActivityTime == testTime)
        
        sessionHandler.updateSessionLastActivityTime()
        let afterTime = sessionHandler.monotonicCurrentTime
        
        #expect(sessionHandler.lastActivityTime >= beforeTime)
        #expect(sessionHandler.lastActivityTime <= afterTime)
    }
    
    // MARK: - Integration Tests

    @Test("given a session configuration with automatic tracking enabled, when completing the session lifecycle, then it should transition through all states correctly")
    func testCompleteSessionLifecycle() {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 5000)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        // Start session
        sessionHandler.startSession(id: 1234567890, type: .manual)
        
        // Session active
        #expect(sessionHandler.sessionId == 1234567890)
        #expect(sessionHandler.sessionType == .manual)
        #expect(sessionHandler.isSessionStart == true)
        
        // Update activity
        sessionHandler.updateSessionLastActivityTime()
        
        // Activity updated
        #expect(sessionHandler.lastActivityTime > 0)
        #expect(sessionHandler.isSessionTimedOut == false)
        
        // End session
        sessionHandler.endSession()
        
        // Session reset
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
    }

    @Test("given a session configuration with automatic tracking enabled, when testing session persistence across handler instances, then it should maintain session state correctly")
    func testSessionPersistence() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionId: UInt64 = 1234567890
        
        // Create first handler and start session
        let sessionHandler1 = SessionHandler(analytics: analytics)
        sessionHandler1.startSession(id: sessionId, type: .manual)
        
        // Create second handler and verify persistence
        let sessionHandler2 = SessionHandler(analytics: analytics)
        #expect(sessionHandler2.sessionId == sessionId)
        #expect(sessionHandler2.sessionType == .manual)
        #expect(sessionHandler2.isSessionStart == true)
    }

    @Test("given a session configuration with automatic tracking enabled, when testing session type transitions, then it should transition between manual and automatic types correctly")
    func testSessionTypeTransitions() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = SwiftTestMockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        // Start manual session
        sessionHandler.startSession(id: 1111111111, type: .manual)
        
        // Should be manual
        #expect(sessionHandler.sessionType == .manual)
        #expect(sessionHandler.sessionId == 1111111111)
        
        // Switch to automatic session
        sessionHandler.startSession(id: 2222222222, type: .automatic)
        
        // Should be automatic
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.sessionId == 2222222222)
        
        // Call automatic session check
        sessionHandler.startAutomaticSessionIfNeeded()
        
        // Should maintain automatic session
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.sessionId != nil)
    }
}

// MARK: - Test Data Structures

struct SessionHandlerTestCase {
    let sessionId: UInt64
    let sessionType: SessionType
    let description: String
}
