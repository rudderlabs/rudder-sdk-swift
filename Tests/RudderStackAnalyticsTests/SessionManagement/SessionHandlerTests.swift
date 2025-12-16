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
    
    @Test("given a session configuration with automatic tracking enabled, when initializing, then it should have a session ID and isSessionStart values")
    func testInitWhenAutomaticSessionTrackingEnabled() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.isSessionStart != SessionConstants.defaultIsSessionStart)
    }
    
    @Test("given a session configuration with automatic tracking disabled, when initializing, then it should not have a session ID and isSessionStart")
    func testInitWhenAutomaticSessionTrackingDisabled() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
    }
    
    @Test("given existing session data in storage, when initializing the session handler, then it should load the session data correctly")
    func testInitializationWithExistingData() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
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
        SessionHandlerTestCase(sessionId: 1234567890, sessionType: .manual),
        SessionHandlerTestCase(sessionId: 9876543210, sessionType: .automatic),
        SessionHandlerTestCase(sessionId: UInt64.max, sessionType: .automatic)
    ])
    func testStartSession(testCase: SessionHandlerTestCase) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: testCase.sessionId, type: testCase.sessionType)
        
        #expect(sessionHandler.sessionId == testCase.sessionId)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == testCase.sessionType)
    }
    
    @Test("given a session configuration with automatic tracking enabled, when starting a session, then it should set the session ID and type correctly")
    func testStartSessionWithZeroId() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: 0, type: .manual)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given a session configuration with automatic tracking enabled, when ending a session, then it should reset the session state")
    func testEndSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: 1234567890, type: .manual)
        sessionHandler.endSession()
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
        #expect(sessionHandler.sessionType == SessionConstants.defaultSessionType)
    }

    @Test("given a session configuration with active session, when refreshing a session, then it should update the session ID and type correctly")
    func testRefreshSessionWithActiveSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        let originalSessionId: UInt64 = 1234567890
        sessionHandler.startSession(id: originalSessionId, type: .manual)
        
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId != originalSessionId, "Session ID should be refreshed")
        #expect(sessionHandler.sessionId != nil, "Session ID should not be nil after refresh")
        #expect(sessionHandler.isSessionStart, "Session should be marked as started")
        #expect(sessionHandler.sessionType == .manual, "Session type should remain manual")
    }
    
    @Test("given a session configuration without active session, when refreshing a session, then it should update the session ID and type correctly")
    func testRefreshSessionWithoutActiveSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId == nil, "Session ID should remain nil when no active session exists")
    }
    
    // MARK: - Automatic Session Tests

    @Test("given automatic session tracking enabled with no active session, when starting an automatic session, then it should create a new automatic session")
    func testStatAutomaticSessionWithNoSessionWhenTrackingEnabled() {
        let config = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: config)
        let handler = SessionHandler(analytics: analytics)
        
        handler.startAutomaticSessionIfNeeded()
        
        #expect(handler.sessionId != nil, "Expected a new session ID when auto-tracking is enabled")
        #expect(handler.sessionType == .automatic, "Expected session type to be automatic")
    }
    
    @Test("given automatic session tracking enabled with an active manual session, when starting an automatic session, then it should switch to automatic session")
    func testStatAutomaticSessionWithActiveManualSessionWhenTrackingEnabled() {
        let config = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: config)
        let handler = SessionHandler(analytics: analytics)
        
        let originalId: UInt64 = 1111111111
        handler.startSession(id: originalId, type: .manual)
        
        handler.startAutomaticSessionIfNeeded()
        
        #expect(handler.sessionId != originalId, "Expected a new session ID when auto-tracking is enabled")
        #expect(handler.sessionType == .automatic, "Expected session type to be automatic")
    }
    
    @Test("given a disabled automatic session tracking tracking with an active automatic session, when starting an automatic session, then it should stop the session")
    func testStatAutomaticSessionWithActiveAutomaticSessionWhenTrackingDisabled() {
        let config = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: config)
        let handler = SessionHandler(analytics: analytics)
        
        handler.startSession(id: 1111111111, type: .automatic)
        handler.startAutomaticSessionIfNeeded()
        
        #expect(handler.sessionId == nil, "Expected no session when auto-tracking is disabled with automatic type")
    }
    
    @Test("given a disabled automatic session tracking with an active manual session, when starting a session, then it should retain the manual session")
    func testStatAutomaticSessionWithActiveManualSessionWhenTrackingDisabled() {
        let config = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: config)
        let handler = SessionHandler(analytics: analytics)
        
        let originalId: UInt64 = 1111111111
        handler.startSession(id: originalId, type: .manual)
        
        handler.startAutomaticSessionIfNeeded()
        
        #expect(handler.sessionId == originalId, "Expected manual session to remain unchanged")
        #expect(handler.sessionType == .manual, "Expected session type to remain manual")
    }
    
    // MARK: - Timeout and State Management Tests

    @Test("given a session configuration with automatic tracking enabled, when testing session timeout, then it should correctly identify timeout states", arguments: [
        (5000, 6000, true),
        (10000, 5000, false),
        (5000, 5000, false)
    ])
    func testSessionTimeout(timeoutMs: UInt64, timeDifferenceMs: UInt64, expectedTimedOut: Bool) {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: timeoutMs)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        let pastTime = sessionHandler.monotonicCurrentTime - timeDifferenceMs
        sessionHandler.updateSessionLastActivityTime(pastTime)
        
        #expect(sessionHandler.isSessionTimedOut == expectedTimedOut)
    }

    @Test("given a session configuration with automatic tracking enabled, when updating the session start flag, then it should set the session start state correctly", arguments: [true, false])
    func testUpdateSessionStart(isSessionStart: Bool) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.updateSessionStart(isSessionStart: isSessionStart)
        
        #expect(sessionHandler.isSessionStart == isSessionStart)
    }

    @Test("given a session configuration with automatic tracking enabled, when updating the session activity time, then it should set the last activity time correctly")
    func testUpdateSessionActivityTime() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
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
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        // Start session
        sessionHandler.startSession(id: 1234567890, type: .manual)
        
        // Session active
        #expect(sessionHandler.sessionId == 1234567890)
        #expect(sessionHandler.sessionType == .manual)
        #expect(sessionHandler.isSessionStart)
        
        // Update activity
        sessionHandler.updateSessionLastActivityTime()
        
        // Activity updated
        #expect(sessionHandler.lastActivityTime > 0)
        #expect(!sessionHandler.isSessionTimedOut)
        
        // End session
        sessionHandler.endSession()
        
        // Session reset
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
    }

    @Test("given a session configuration with automatic tracking enabled, when testing session persistence across handler instances, then it should maintain session state correctly")
    func testSessionPersistence() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionId: UInt64 = 1234567890
        
        // Create first handler and start session
        let sessionHandler1 = SessionHandler(analytics: analytics)
        sessionHandler1.startSession(id: sessionId, type: .manual)
        
        // Create second handler and verify persistence
        let sessionHandler2 = SessionHandler(analytics: analytics)
        #expect(sessionHandler2.sessionId == sessionId)
        #expect(sessionHandler2.sessionType == .manual)
        #expect(sessionHandler2.isSessionStart)
    }

    @Test("given a session configuration with automatic tracking enabled, when testing session type transitions, then it should transition between manual and automatic types correctly")
    func testSessionTypeTransitions() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
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
}
