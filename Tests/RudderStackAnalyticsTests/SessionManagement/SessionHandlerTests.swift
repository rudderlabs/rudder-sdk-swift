//
//  SessionHandlerTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SessionHandler Tests")
struct SessionHandlerTests {
    
    // MARK: - Initialization Tests
    
    @Test("given automatic session tracking enabled, when session handler is initialized, then it should have a session ID and isSessionStart values")
    func testInitWhenAutomaticSessionTrackingEnabled() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.isSessionStart != SessionConstants.defaultIsSessionStart)
    }
    
    @Test("given automatic session tracking disabled, when session handler is initialized, then it should not have a session ID and isSessionStart")
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
    
    @Test("given no session id stored previously, when automatic session enabled and app launched, then new automatic session is started with correct session id")
    func testNewAutomaticSessionStartsWithCorrectIdWhenNoPreviousSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        
        let beforeTime = UInt64(Date().timeIntervalSince1970)
        let sessionHandler = SessionHandler(analytics: analytics)
        let afterTime = UInt64(Date().timeIntervalSince1970)
        
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.sessionId! >= beforeTime)
        #expect(sessionHandler.sessionId! <= afterTime)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    // MARK: - Session Management Tests
    
    @Test("given a session configuration, when starting a session, then it should set the session ID and type correctly", arguments: [
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
    
    @Test("given a session configuration, when starting a session with zero id, then session id should be nil")
    func testStartSessionWithZeroId() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.startSession(id: 0, type: .manual)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given an active session, when ending the session, then it should reset the session state")
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
    
    @Test("given automatic session enabled previously, when session is ended with endSession, then all the session variables are cleared")
    func testEndSessionClearsAllVariablesForAutomaticSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        storage.write(value: "1234567890", key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        storage.write(value: true, key: Constants.storageKeys.isSessionStart)
        storage.write(value: "9876543210", key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        sessionHandler.endSession()
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.isSessionStart == false)
        #expect(sessionHandler.lastActivityTime == 0)
    }
    
    @Test("given manual session enabled previously, when session is ended with endSession, then all the session variables are cleared")
    func testEndSessionClearsAllVariablesForManualSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        storage.write(value: "1234567890", key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        storage.write(value: true, key: Constants.storageKeys.isSessionStart)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        sessionHandler.endSession()
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == false)
    }
    
    @Test("given an active session, when refreshing a session, then it should update the session ID while maintaining session type")
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
    
    @Test("given automatic session enabled previously, when reset called (which internally calls refreshSession), then session is refreshed")
    func testRefreshSessionForAutomaticSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let previousSessionId: UInt64 = 1234567890
        storage.write(value: String(previousSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId != previousSessionId)
    }
    
    @Test("given manual session enabled previously, when reset called (which internally calls refreshSession), then session is refreshed")
    func testRefreshSessionForManualSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let previousSessionId: UInt64 = 1234567890
        storage.write(value: String(previousSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId != previousSessionId)
    }
    
    @Test("given no active session, when refreshing a session, then it should remain nil")
    func testRefreshSessionWithoutActiveSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId == nil, "Session ID should remain nil when no active session exists")
    }
    
    // MARK: - Automatic Session Launch Tests
    
    @Test("given an automatic session enabled, when app is launched and session is timed out, then new session starts")
    func testAutomaticSessionTimedOutOnLaunchStartsNewSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 5000)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let initialSessionId: UInt64 = 1234567890
        storage.write(value: String(initialSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        // Simulate last activity 10 seconds ago (past timeout of 5 seconds)
        let pastTime = UInt64(ProcessInfo.processInfo.systemUptime * 1000) - 10000
        storage.write(value: String(pastTime), key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId != initialSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    @Test("given previous session was manual, when automatic session enabled and app launched, then new automatic session starts")
    func testManualSessionReplacedWithAutomaticOnLaunch() {
        let configuration = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let initialSessionId: UInt64 = 1234567890
        storage.write(value: String(initialSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId != initialSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    @Test("given previous session was manual, when automatic session is disabled and app launched, then previous session variables are not cleared")
    func testManualSessionPersistsWhenAutomaticTrackingDisabled() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let previousSessionId: UInt64 = 1234567890
        storage.write(value: String(previousSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId == previousSessionId)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given previous session was automatic, when automatic session is disabled and app launched, then previous session variables are cleared")
    func testAutomaticSessionClearedWhenAutomaticTrackingDisabled() {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let previousSessionId: UInt64 = 1234567890
        let lastActivityTime: UInt64 = 9876543210
        storage.write(value: String(previousSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        storage.write(value: String(lastActivityTime), key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.lastActivityTime == 0)
    }
    
    // MARK: - Timeout and State Management Tests
    
    @Test("given a session configuration, when testing session timeout, then it should correctly identify timeout states", arguments: [
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
    
    @Test("given a session configuration, when updating the session start flag, then it should set the session start state correctly", arguments: [true, false])
    func testUpdateSessionStart(isSessionStart: Bool) {
        let configuration = SessionConfiguration(automaticSessionTracking: false)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = SessionHandler(analytics: analytics)
        
        sessionHandler.updateSessionStart(isSessionStart: isSessionStart)
        
        #expect(sessionHandler.isSessionStart == isSessionStart)
    }
    
    @Test("given a session configuration, when updating the session activity time, then it should set the last activity time correctly")
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
    
    // MARK: - Foreground Tests
    
    @Test("given automatic session ongoing previously, when app is foregrounded and session is timed out, then new session starts")
    func testForegroundWithTimedOutSessionStartsNewSession() async {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 5000)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let previousSessionId: UInt64 = 1234567890
        storage.write(value: String(previousSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        // Set last activity time to be beyond timeout
        let pastTime = UInt64(ProcessInfo.processInfo.systemUptime * 1000) - 10000
        storage.write(value: String(pastTime), key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        // Simulate foreground event
        NotificationCenter.default.post(name: AppLifecycleEvent.foreground.notificationName, object: nil)
        
        // Allow async observers to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sessionHandler.sessionId != previousSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    // MARK: - System Restart Tests
    
    @Test("given automatic session enabled and the system is restarted (monotonic time less than last activity), when app is launched, then new session starts")
    func testSystemRestartOnLaunchStartsNewSession() {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 300000)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let storage = analytics.configuration.storage
        
        let initialSessionId: UInt64 = 1234567890
        // Simulate system restart: last activity time is slightly ahead of current monotonic time.
        // With wrapping subtraction (monotonicCurrentTime &- lastActivityTime), this produces
        // a very large value (close to UInt64.max), which exceeds the session timeout.
        let currentMonotonicTime = UInt64(ProcessInfo.processInfo.systemUptime * 1000.0)
        let veryLargeLastActivityTime: UInt64 = currentMonotonicTime + 1000
        
        storage.write(value: String(initialSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        storage.write(value: String(veryLargeLastActivityTime), key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        // After system restart, monotonic time is small, so session should be timed out
        #expect(sessionHandler.sessionId != initialSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    // MARK: - Integration Tests
    
    @Test("given a session configuration, when completing the session lifecycle, then it should transition through all states correctly")
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
    
    @Test("given a session configuration, when testing session persistence across handler instances, then it should maintain session state correctly")
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
    
    @Test("given a session configuration, when testing session type transitions, then it should transition between manual and automatic types correctly")
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
    }
}

// MARK: - Test Data Structures

struct SessionHandlerTestCase {
    let sessionId: UInt64
    let sessionType: SessionType
}
