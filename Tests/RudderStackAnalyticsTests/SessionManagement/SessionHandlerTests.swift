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
    private static let storedSessionId: UInt64 = 1234567890
    private static let shortTimeoutInMillis: UInt64 = 5000
    
    // MARK: - Initialization Tests
    
    @Test("given automatic session tracking, when the SDK starts, then no session starts", arguments: [true, false])
    func testInitStartsNoSession(automaticSessionTracking: Bool) {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: automaticSessionTracking))
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
    }
    
    @Test("given existing session data in storage, when initializing the session handler, then it should load the session data correctly")
    func testInitializationWithExistingData() {
        let storage = MockStorage()
        storage.write(value: String(Self.storedSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: true, key: Constants.storageKeys.isSessionStart)
        storage.write(value: true, key: Constants.storageKeys.isManualSession)
        storage.write(value: "9876543210", key: Constants.storageKeys.lastActivityTime)
        
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false), storage: storage)
        
        #expect(sessionHandler.sessionId == Self.storedSessionId)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
        #expect(sessionHandler.lastActivityTime == 9876543210)
    }
    
    @Test("given a manual session from an earlier process, when the SDK starts with automatic tracking, then the manual session is cleared")
    func testStaleManualSessionIsClearedAtInit() {
        let storage = storageWithSession(isManual: true)
        
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true), storage: storage)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    @Test("given previous session was manual, when automatic session is disabled and app launched, then previous session variables are not cleared")
    func testManualSessionPersistsWhenAutomaticTrackingDisabled() {
        let storage = storageWithSession(isManual: true)
        
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false), storage: storage)
        
        #expect(sessionHandler.sessionId == Self.storedSessionId)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given previous session was automatic, when automatic session is disabled and app launched, then previous session variables are cleared")
    func testAutomaticSessionClearedWhenAutomaticTrackingDisabled() {
        let storage = storageWithSession(isManual: false, lastActivityTime: 9876543210)
        
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false), storage: storage)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.lastActivityTime == 0)
    }
    
    // MARK: - First Foreground Tests
    
    @Test("given no stored session, when the app comes to the foreground for the first time, then a new automatic session starts")
    func testFirstForegroundStartsSessionWhenNoneIsStored() {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        let sessionHandler = sessionHandler(of: analytics)
        let beforeTime = UInt64(Date().timeIntervalSince1970)
        let beforeTimeInMillis = sessionHandler.systemCurrentTime
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let sessionId = sessionHandler.sessionId ?? 0
        #expect(sessionId >= beforeTime)
        #expect(sessionId <= UInt64(Date().timeIntervalSince1970))
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.lastActivityTime >= beforeTimeInMillis, "A new session records its activity time at start.")
    }
    
    @Test("given a stored automatic session inside the timeout, when the app comes to the foreground for the first time, then the session continues")
    func testFirstForegroundContinuesLiveSession() {
        let storage = storageWithSession(isManual: false, lastActivityTime: currentTimeInMillis - 1000)
        let analytics = MockProvider.createMockAnalytics(storage: storage, sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        #expect(sessionHandler(of: analytics).sessionId == Self.storedSessionId)
    }
    
    @Test("given a stored automatic session past the timeout, when the app comes to the foreground for the first time, then a new session starts")
    func testFirstForegroundReplacesTimedOutSession() {
        let storage = storageWithSession(isManual: false, lastActivityTime: currentTimeInMillis - 10000)
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: Self.shortTimeoutInMillis)
        let analytics = MockProvider.createMockAnalytics(storage: storage, sessionConfig: configuration)
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let sessionHandler = sessionHandler(of: analytics)
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.sessionId != Self.storedSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    @Test("given a manual session from an earlier process, when the app comes to the foreground for the first time, then an automatic session starts")
    func testFirstForegroundStartsAutomaticSessionAfterStaleManualSession() {
        let storage = storageWithSession(isManual: true)
        let analytics = MockProvider.createMockAnalytics(storage: storage, sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let sessionHandler = sessionHandler(of: analytics)
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.sessionId != Self.storedSessionId)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    @Test("given an app already in the foreground, when the session handler is created, then a session starts at once")
    func testSessionStartsAtInitWhenAppIsAlreadyInForeground() {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: false))
        analytics.simulateLifecycleEvent(.becomeActive)
        analytics.configuration.sessionConfiguration = SessionConfiguration(automaticSessionTracking: true)
        
        let sessionHandler = SessionHandler(analytics: analytics)
        
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.sessionType == .automatic)
    }
    
    // MARK: - Later Foreground Tests
    
    @Test("given a session, when the app returns to the foreground, then only a timed-out session is replaced", arguments: [
        (idleTimeInMillis: UInt64(1000), isReplaced: false),
        (idleTimeInMillis: UInt64(10000), isReplaced: true)
    ])
    func testLaterForegroundReplacesOnlyTimedOutSession(idleTimeInMillis: UInt64, isReplaced: Bool) {
        let storage = storageWithSession(isManual: false, lastActivityTime: currentTimeInMillis - 1000)
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: Self.shortTimeoutInMillis)
        let analytics = MockProvider.createMockAnalytics(storage: storage, sessionConfig: configuration)
        let sessionHandler = sessionHandler(of: analytics)
        analytics.simulateLifecycleEvent(.becomeActive)
        analytics.simulateLifecycleEvent(.background)
        sessionHandler.updateSessionLastActivityTime(currentTimeInMillis - idleTimeInMillis)
        
        analytics.simulateLifecycleEvent(.foreground)
        
        #expect((sessionHandler.sessionId != Self.storedSessionId) == isReplaced)
    }
    
    @Test("given the app ended the session, when a foreground callback arrives, then no session starts")
    func testForegroundAfterEndSessionStartsNoSession() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true))
        sessionHandler.endSession()
        
        sessionHandler.onForeground()
        
        #expect(sessionHandler.sessionId == nil)
    }
    
    @Test("given the app started a manual session, when a foreground callback arrives, then the manual session remains")
    func testForegroundAfterManualStartKeepsManualSession() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true))
        sessionHandler.startSession(id: Self.storedSessionId, type: .manual)
        
        sessionHandler.onForeground()
        
        #expect(sessionHandler.sessionId == Self.storedSessionId)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    // MARK: - Background Event Tests
    
    @Test("given background events are not included, when a background event arrives, then no session starts")
    func testBackgroundEventStartsNoSessionWhenNotIncluded() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true))
        
        sessionHandler.startSessionOnBackgroundEventIfNeeded()
        
        #expect(sessionHandler.sessionId == nil)
    }
    
    @Test("given background events are included and no session exists, when a background event arrives, then a new session starts")
    func testBackgroundEventStartsSessionWhenNoneExists() {
        let sessionHandler = makeSessionHandler(Self.includingBackgroundEvents)
        
        sessionHandler.startSessionOnBackgroundEventIfNeeded()
        
        #expect(sessionHandler.sessionId != nil)
        #expect(sessionHandler.sessionType == .automatic)
        #expect(sessionHandler.isSessionStart)
    }
    
    @Test("given background events are included, when a background event arrives, then only a timed-out session is replaced", arguments: [
        (idleTimeInMillis: UInt64(1000), isReplaced: false),
        (idleTimeInMillis: UInt64(10000), isReplaced: true)
    ])
    func testBackgroundEventReplacesOnlyTimedOutSession(idleTimeInMillis: UInt64, isReplaced: Bool) {
        let storage = storageWithSession(isManual: false, lastActivityTime: currentTimeInMillis - idleTimeInMillis)
        let sessionHandler = makeSessionHandler(Self.includingBackgroundEvents, storage: storage)
        
        sessionHandler.startSessionOnBackgroundEventIfNeeded()
        
        #expect((sessionHandler.sessionId != Self.storedSessionId) == isReplaced)
    }
    
    @Test("given a background event started a session, when the app comes to the foreground at once, then the same session continues")
    func testForegroundAfterBackgroundEventContinuesSession() {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: Self.includingBackgroundEvents)
        let sessionHandler = sessionHandler(of: analytics)
        sessionHandler.startSessionOnBackgroundEventIfNeeded()
        let backgroundSessionId = sessionHandler.sessionId
        sessionHandler.updateSessionStart(isSessionStart: false)
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        #expect(sessionHandler.sessionId == backgroundSessionId)
        #expect(!sessionHandler.isSessionStart, "A continued session must not report its start again.")
    }
    
    @Test("given the app ended the session or started a manual one, when a background event arrives, then the app's choice remains", arguments: [true, false])
    func testBackgroundEventDoesNotOverrideTheApp(startsManualSession: Bool) {
        let sessionHandler = makeSessionHandler(Self.includingBackgroundEvents)
        if startsManualSession {
            sessionHandler.startSession(id: Self.storedSessionId, type: .manual)
        } else {
            sessionHandler.endSession()
        }
        
        sessionHandler.startSessionOnBackgroundEventIfNeeded()
        
        #expect(sessionHandler.sessionId == (startsManualSession ? Self.storedSessionId : nil))
    }
    
    // MARK: - Visible Session ID Tests
    
    @Test("given an automatic session, when the visible session ID is read, then it is the ID that an event sent now would carry", arguments: [
        (includesBackgroundEvents: false, isInForeground: true, isTimedOut: false, isVisible: true),
        (includesBackgroundEvents: false, isInForeground: false, isTimedOut: false, isVisible: false),
        (includesBackgroundEvents: true, isInForeground: false, isTimedOut: false, isVisible: true),
        (includesBackgroundEvents: true, isInForeground: false, isTimedOut: true, isVisible: false),
        (includesBackgroundEvents: true, isInForeground: true, isTimedOut: false, isVisible: true)
    ])
    func testVisibleSessionIdForAutomaticSession(includesBackgroundEvents: Bool, isInForeground: Bool, isTimedOut: Bool, isVisible: Bool) {
        let configuration = SessionConfiguration(
            automaticSessionTracking: true,
            sessionTimeoutInMillis: Self.shortTimeoutInMillis,
            includeBackgroundEventsInSession: includesBackgroundEvents
        )
        let analytics = MockProvider.createMockAnalytics(sessionConfig: configuration)
        let sessionHandler = sessionHandler(of: analytics)
        analytics.simulateLifecycleEvent(.becomeActive)
        if !isInForeground {
            analytics.simulateLifecycleEvent(.background)
        }
        if isTimedOut {
            sessionHandler.updateSessionLastActivityTime(currentTimeInMillis - 10000)
        }
        
        #expect((sessionHandler.visibleSessionId != nil) == isVisible)
        #expect((analytics.sessionId != nil) == isVisible)
    }
    
    @Test("given a manual session, when the visible session ID is read in the background, then it is the manual session ID")
    func testVisibleSessionIdForManualSession() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true))
        
        sessionHandler.startSession(id: Self.storedSessionId, type: .manual)
        
        #expect(sessionHandler.visibleSessionId == Self.storedSessionId)
    }
    
    @Test("given no session, when the visible session ID is read, then it is nil")
    func testVisibleSessionIdWithoutSession() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true))
        
        #expect(sessionHandler.visibleSessionId == nil)
    }
    
    // MARK: - Session Management Tests
    
    @Test("given a session configuration, when starting a session, then it should set the session ID and type correctly", arguments: [
        SessionHandlerTestCase(sessionId: 1234567890, sessionType: .manual),
        SessionHandlerTestCase(sessionId: 9876543210, sessionType: .automatic),
        SessionHandlerTestCase(sessionId: UInt64.max, sessionType: .automatic)
    ])
    func testStartSession(testCase: SessionHandlerTestCase) {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false))
        let beforeTimeInMillis = sessionHandler.systemCurrentTime
        
        sessionHandler.startSession(id: testCase.sessionId, type: testCase.sessionType)
        
        #expect(sessionHandler.sessionId == testCase.sessionId)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == testCase.sessionType)
        #expect(sessionHandler.lastActivityTime >= beforeTimeInMillis)
    }
    
    @Test("given a session configuration, when starting a session with zero id, then session id should be nil")
    func testStartSessionWithZeroId() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false))
        
        sessionHandler.startSession(id: 0, type: .manual)
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.isSessionStart)
        #expect(sessionHandler.sessionType == .manual)
    }
    
    @Test("given a session, when ending the session, then all the session variables are cleared", arguments: [SessionType.manual, .automatic])
    func testEndSessionClearsAllVariables(sessionType: SessionType) {
        let storage = MockStorage()
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: sessionType == .automatic), storage: storage)
        sessionHandler.startSession(id: Self.storedSessionId, type: sessionType)
        
        sessionHandler.endSession()
        
        #expect(sessionHandler.sessionId == nil)
        #expect(sessionHandler.sessionType == SessionConstants.defaultSessionType)
        #expect(sessionHandler.isSessionStart == SessionConstants.defaultIsSessionStart)
        #expect(sessionHandler.lastActivityTime == 0)
        let storedSessionId: String? = storage.read(key: Constants.storageKeys.sessionId)
        #expect(storedSessionId == nil)
    }
    
    @Test("given an active session, when refreshing a session, then it should update the session ID while maintaining session type", arguments: [
        SessionType.manual, .automatic
    ])
    func testRefreshSessionWithActiveSession(sessionType: SessionType) {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: sessionType == .automatic))
        sessionHandler.startSession(id: Self.storedSessionId, type: sessionType)
        sessionHandler.updateSessionStart(isSessionStart: false)
        
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId != nil, "Session ID should not be nil after refresh")
        #expect(sessionHandler.sessionId != Self.storedSessionId, "Session ID should be refreshed")
        #expect(sessionHandler.isSessionStart, "Session should be marked as started")
        #expect(sessionHandler.sessionType == sessionType, "Session type should remain the same")
    }
    
    @Test("given no active session, when refreshing a session, then it should remain nil")
    func testRefreshSessionWithoutActiveSession() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false))
        
        sessionHandler.refreshSession()
        
        #expect(sessionHandler.sessionId == nil, "Session ID should remain nil when no active session exists")
    }
    
    @Test("given a session configuration, when testing session persistence across handler instances, then it should maintain session state correctly")
    func testSessionPersistence() {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: false))
        sessionHandler(of: analytics).startSession(id: Self.storedSessionId, type: .manual)
        
        let secondSessionHandler = SessionHandler(analytics: analytics)
        
        #expect(secondSessionHandler.sessionId == Self.storedSessionId)
        #expect(secondSessionHandler.sessionType == .manual)
        #expect(secondSessionHandler.isSessionStart)
    }
    
    // MARK: - Timeout and State Management Tests
    
    @Test("given a session configuration, when testing session timeout, then it should correctly identify timeout states", arguments: [
        (5000, 6000, true),
        (10000, 5000, false),
        (5000, 5000, false)
    ])
    func testSessionTimeout(timeoutMs: UInt64, timeDifferenceMs: UInt64, expectedTimedOut: Bool) {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: timeoutMs))
        
        let pastTime = sessionHandler.systemCurrentTime - timeDifferenceMs
        sessionHandler.updateSessionLastActivityTime(pastTime)
        
        #expect(sessionHandler.isSessionTimedOut == expectedTimedOut)
    }
    
    @Test("given a last activity time set to a future timestamp, when checking session timeout, then it should be considered timed out due to clock tampering")
    func testSessionTimedOutWhenLastActivityTimeIsInFuture() {
        let configuration = SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: Self.shortTimeoutInMillis)
        let sessionHandler = makeSessionHandler(configuration)
        
        // As would happen if the system clock was moved backward after the time was stored.
        sessionHandler.updateSessionLastActivityTime(sessionHandler.systemCurrentTime + 60000)
        
        #expect(sessionHandler.isSessionTimedOut)
    }
    
    @Test("given a session configuration, when updating the session start flag, then it should set the session start state correctly", arguments: [true, false])
    func testUpdateSessionStart(isSessionStart: Bool) {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false))
        
        sessionHandler.updateSessionStart(isSessionStart: isSessionStart)
        
        #expect(sessionHandler.isSessionStart == isSessionStart)
    }
    
    @Test("given a session configuration, when updating the session activity time, then it should set the last activity time correctly")
    func testUpdateSessionActivityTime() {
        let sessionHandler = makeSessionHandler(SessionConfiguration(automaticSessionTracking: false))
        let testTime: UInt64 = 1234567890
        let beforeTime = sessionHandler.systemCurrentTime
        
        sessionHandler.updateSessionLastActivityTime(testTime)
        #expect(sessionHandler.lastActivityTime == testTime)
        
        sessionHandler.updateSessionLastActivityTime()
        #expect(sessionHandler.lastActivityTime >= beforeTime)
        #expect(sessionHandler.lastActivityTime <= sessionHandler.systemCurrentTime)
    }
    
    // MARK: - Lifecycle Activity Tests
    
    @Test("given a session in the foreground, when the app moves to the background, then the last activity time is recorded")
    func testBackgroundRecordsActivityTime() {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        let sessionHandler = sessionHandler(of: analytics)
        analytics.simulateLifecycleEvent(.becomeActive)
        sessionHandler.updateSessionLastActivityTime(0)
        
        analytics.simulateLifecycleEvent(.background)
        
        #expect(sessionHandler.lastActivityTime != 0)
    }
    
    @Test("given a session, when the app terminates, then only an app in the foreground records the last activity time", arguments: [true, false])
    func testTerminateRecordsActivityTimeOnlyInForeground(isInForeground: Bool) {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        let sessionHandler = sessionHandler(of: analytics)
        analytics.simulateLifecycleEvent(.becomeActive)
        if !isInForeground {
            analytics.simulateLifecycleEvent(.background)
        }
        sessionHandler.updateSessionLastActivityTime(0)
        
        analytics.simulateLifecycleEvent(.terminate)
        
        #expect((sessionHandler.lastActivityTime != 0) == isInForeground)
    }
    
    // MARK: - Race Tests
    
    @Test("given an automatic session start in flight, when the app ends the session on another thread, then no session remains", arguments: [
        AutomaticStartTrigger.foreground, .backgroundEvent
    ])
    func testEndSessionWinsARaceWithAnAutomaticStart(trigger: AutomaticStartTrigger) {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: Self.includingBackgroundEvents)
        
        for _ in 0..<Self.raceIterations {
            let sessionHandler = SessionHandler(analytics: analytics)
            
            race({ sessionHandler.endSession() }, { trigger.start(on: sessionHandler) })
            
            #expect(sessionHandler.sessionId == nil)
        }
    }
    
    @Test("given an automatic session start in flight, when the app starts a manual session on another thread, then the manual session remains", arguments: [
        AutomaticStartTrigger.foreground, .backgroundEvent
    ])
    func testManualSessionWinsARaceWithAnAutomaticStart(trigger: AutomaticStartTrigger) {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: Self.includingBackgroundEvents)
        
        for _ in 0..<Self.raceIterations {
            let sessionHandler = SessionHandler(analytics: analytics)
            
            race({ sessionHandler.startSession(id: Self.storedSessionId, type: .manual) }, { trigger.start(on: sessionHandler) })
            
            #expect(sessionHandler.sessionId == Self.storedSessionId)
            #expect(sessionHandler.sessionType == .manual)
            sessionHandler.endSession()
        }
    }
}

// MARK: - Helpers

extension SessionHandlerTests {
    private static let raceIterations = 200
    
    private static var includingBackgroundEvents: SessionConfiguration {
        return SessionConfiguration(
            automaticSessionTracking: true,
            sessionTimeoutInMillis: shortTimeoutInMillis,
            includeBackgroundEventsInSession: true
        )
    }
    
    private var currentTimeInMillis: UInt64 {
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }
    
    private func makeSessionHandler(_ configuration: SessionConfiguration, storage: MockStorage = MockStorage()) -> SessionHandler {
        return sessionHandler(of: MockProvider.createMockAnalytics(storage: storage, sessionConfig: configuration))
    }
    
    private func sessionHandler(of analytics: Analytics) -> SessionHandler {
        return analytics.sessionHandler ?? SessionHandler(analytics: analytics)
    }
    
    private func storageWithSession(isManual: Bool, lastActivityTime: UInt64? = nil) -> MockStorage {
        let storage = MockStorage()
        storage.write(value: String(Self.storedSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: isManual, key: Constants.storageKeys.isManualSession)
        if let lastActivityTime {
            storage.write(value: String(lastActivityTime), key: Constants.storageKeys.lastActivityTime)
        }
        return storage
    }
    
    /// Runs both calls at the same time on two threads and returns when both are done.
    private func race(_ first: @escaping () -> Void, _ second: @escaping () -> Void) {
        let calls = [first, second]
        DispatchQueue.concurrentPerform(iterations: calls.count) { calls[$0]() }
    }
}

// MARK: - Test Data Structures

struct SessionHandlerTestCase {
    let sessionId: UInt64
    let sessionType: SessionType
}

enum AutomaticStartTrigger {
    case foreground
    case backgroundEvent
    
    func start(on sessionHandler: SessionHandler) {
        switch self {
        case .foreground: sessionHandler.onForeground()
        case .backgroundEvent: sessionHandler.startSessionOnBackgroundEventIfNeeded()
        }
    }
}
