//
//  SessionActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("SessionActionTests Tests")
struct SessionActionTests {
    
    // MARK: - StartSessionAction Tests
    
    @Test("given various session start parameters, when reducing, then id, isStart, and type are all set atomically", arguments: [
        (UInt64(1234567890), SessionType.automatic),
        (UInt64(9876543210), SessionType.manual),
        (UInt64.max, SessionType.automatic)
    ])
    func testStartSession(sessionId: UInt64, sessionType: SessionType) {
        let initialState = SessionInfo(id: 1111111111, type: .manual, isStart: false, lastActivityTime: 9999999999)
        let action = StartSessionAction(sessionId: sessionId, sessionType: sessionType)
        let newState = action.reduce(currentState: initialState)

        #expect(newState.id == sessionId)
        #expect(newState.isStart == true)
        #expect(newState.type == sessionType)
        #expect(newState.lastActivityTime == initialState.lastActivityTime)
    }

    @Test("given an active session, when start session action is applied, then state immutability is preserved")
    func testStartSessionImmutability() {
        let originalState = SessionInfo(id: 1111111111, type: .manual, isStart: false, lastActivityTime: 9876543210)
        let action = StartSessionAction(sessionId: 2222222222, sessionType: .automatic)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.id == 1111111111)
        #expect(originalState.isStart == false)
        #expect(originalState.type == .manual)
        #expect(newState.id == 2222222222)
        #expect(newState.isStart == true)
        #expect(newState.type == .automatic)
        #expect(newState.lastActivityTime == originalState.lastActivityTime)
    }
    
    // MARK: - UpdateIsSessionStartAction Tests
    
    @Test("given various session start flags, when updating, then the new flag is set", arguments: [
        (false, true),
        (true, false),
        (false, false),
        (true, true)
    ])
    func testUpdateSessionStart(initialStart: Bool, newStart: Bool) {
        let initialState = SessionInfo(isStart: initialStart)
        let action = UpdateIsSessionStartAction(isSessionStart: newStart)
        
        let updatedState = action.reduce(currentState: initialState)
        
        #expect(updatedState.isStart == newStart)
        // Verify other properties remain unchanged
        #expect(updatedState.id == initialState.id)
        #expect(updatedState.type == initialState.type)
        #expect(updatedState.lastActivityTime == initialState.lastActivityTime)
    }
    
    @Test("given various session start flags, when updating, then state immutability is preserved")
    func testSessionStartImmutability() {
        let originalState = SessionInfo(id: 1234567890, type: .automatic, isStart: false, lastActivityTime: 5555555555)
        let action = UpdateIsSessionStartAction(isSessionStart: true)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(!originalState.isStart) // Original state unchanged
        #expect(newState.isStart) // New state has updated flag
        #expect(newState.id == originalState.id)
        #expect(newState.type == originalState.type)
        #expect(newState.lastActivityTime == originalState.lastActivityTime)
    }
    
    // MARK: - UpdateSessionLastActivityAction Tests
    
    @Test("given various last activity times, when updating, then the new time is set", arguments: [
        UInt64(0),
        UInt64(1234567890),
        UInt64.max,
    ])
    func testUpdateLastActivityTime(newActivityTime: UInt64) {
        let initialState = SessionInfo(lastActivityTime: 9999999999)
        let action = UpdateSessionLastActivityAction(lastActivityTime: newActivityTime)
        
        let updatedState = action.reduce(currentState: initialState)
        
        #expect(updatedState.lastActivityTime == newActivityTime)
        // Verify other properties remain unchanged
        #expect(updatedState.id == initialState.id)
        #expect(updatedState.type == initialState.type)
        #expect(updatedState.isStart == initialState.isStart)
    }
    
    @Test("given various last activity times, when updating, then state immutability is preserved")
    func testLastActivityTimeImmutability() {
        let originalState = SessionInfo(id: 8888888888, type: .automatic, isStart: false, lastActivityTime: 1111111111)
        let action = UpdateSessionLastActivityAction(lastActivityTime: 2222222222)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.lastActivityTime == 1111111111) // Original state unchanged
        #expect(newState.lastActivityTime == 2222222222) // New state has updated time
        #expect(newState.id == originalState.id)
        #expect(newState.type == originalState.type)
        #expect(newState.isStart == originalState.isStart)
    }
    
    @Test("given various session states, when ending, then all values reset to defaults", arguments: [
        SessionTestCase(
            id: 1234567890,
            type: .manual,
            isStart: true,
            lastActivityTime: 9876543210,
            description: "active manual session"
        ),
        SessionTestCase(
            id: UInt64.max,
            type: .automatic,
            isStart: false,
            lastActivityTime: 0,
            description: "automatic session with max ID"
        ),
        SessionTestCase(
            id: 0,
            type: .manual,
            isStart: true,
            lastActivityTime: UInt64.max,
            description: "manual session with edge values"
        )
    ])
    func testEndSession(testCase: SessionTestCase) {
        let initialState = SessionInfo(
            id: testCase.id,
            type: testCase.type,
            isStart: testCase.isStart,
            lastActivityTime: testCase.lastActivityTime
        )
        let action = EndSessionAction()
        
        let endedState = action.reduce(currentState: initialState)
        
        #expect(endedState.id == SessionConstants.defaultSessionId)
        #expect(endedState.type == SessionConstants.defaultSessionType)
        #expect(endedState.isStart == SessionConstants.defaultIsSessionStart)
        #expect(endedState.lastActivityTime == SessionConstants.defaultSessionLastActivityTime)
    }
    
    @Test("given a session state, when ending, then a new state instance is created")
    func testEndSessionCreatesNewInstance() {
        let originalState = SessionInfo(id: 1234567890, type: .manual, isStart: true, lastActivityTime: 9876543210)
        let action = EndSessionAction()
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.id == 1234567890)
        #expect(originalState.type == .manual)
        #expect(originalState.isStart)
        #expect(originalState.lastActivityTime == 9876543210)
        
        #expect(newState.id == SessionConstants.defaultSessionId)
        #expect(newState.type == SessionConstants.defaultSessionType)
        #expect(newState.isStart == SessionConstants.defaultIsSessionStart)
        #expect(newState.lastActivityTime == SessionConstants.defaultSessionLastActivityTime)
    }
}

// MARK: - EndSessionAction Tests

struct SessionTestCase {
    let id: UInt64
    let type: SessionType
    let isStart: Bool
    let lastActivityTime: UInt64
    let description: String
}
