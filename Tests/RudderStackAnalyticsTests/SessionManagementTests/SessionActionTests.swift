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
    
    // MARK: - UpdateSessionIdAction Tests
    
    @Test("given various session IDs, when updating, then the new ID is set", arguments: [
        (UInt64(0), UInt64(1234567890)),
        (UInt64(9999999999), UInt64(0)),
        (UInt64(1111111111), UInt64.max),
        (UInt64.max, UInt64(5555555555))
    ])
    func test_updateSessionId(initialId: UInt64, newId: UInt64) {
        let initialState = SessionInfo(id: initialId)
        let action = UpdateSessionIdAction(sessionId: newId)
        
        let updatedState = action.reduce(currentState: initialState)
        
        #expect(updatedState.id == newId)
        // Verify other properties remain unchanged
        #expect(updatedState.type == initialState.type)
        #expect(updatedState.isStart == initialState.isStart)
        #expect(updatedState.lastActivityTime == initialState.lastActivityTime)
    }
    
    @Test("given various session IDs, when updating, then state immutability is preserved")
    func test_sessionIdImmutability() {
        let originalState = SessionInfo(id: 1111111111, type: .manual, isStart: true, lastActivityTime: 9876543210)
        let action = UpdateSessionIdAction(sessionId: 2222222222)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.id == 1111111111) // Original state unchanged
        #expect(newState.id == 2222222222) // New state has updated ID
        #expect(newState.type == originalState.type)
        #expect(newState.isStart == originalState.isStart)
        #expect(newState.lastActivityTime == originalState.lastActivityTime)
    }
    
    // MARK: - UpdateIsSessionStartAction Tests
    
    @Test("given various session start flags, when updating, then the new flag is set", arguments: [
        (false, true),
        (true, false),
        (false, false),
        (true, true)
    ])
    func test_updateSessionStart(initialStart: Bool, newStart: Bool) {
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
    func test_sessionStartImmutability() {
        let originalState = SessionInfo(id: 1234567890, type: .automatic, isStart: false, lastActivityTime: 5555555555)
        let action = UpdateIsSessionStartAction(isSessionStart: true)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.isStart == false) // Original state unchanged
        #expect(newState.isStart == true) // New state has updated flag
        #expect(newState.id == originalState.id)
        #expect(newState.type == originalState.type)
        #expect(newState.lastActivityTime == originalState.lastActivityTime)
    }
    
    // MARK: - UpdateSessionTypeAction Tests
    
    @Test("given various session types, when updating, then the new type is set", arguments: [
        (SessionType.automatic, SessionType.manual),
        (SessionType.manual, SessionType.automatic),
        (SessionType.automatic, SessionType.automatic),
        (SessionType.manual, SessionType.manual)
    ])
    func test_updateSessionType(initialType: SessionType, newType: SessionType) {
        let initialState = SessionInfo(type: initialType)
        let action = UpdateSessionTypeAction(sessionType: newType)
        
        let updatedState = action.reduce(currentState: initialState)
        
        #expect(updatedState.type == newType)
        // Verify other properties remain unchanged
        #expect(updatedState.id == initialState.id)
        #expect(updatedState.isStart == initialState.isStart)
        #expect(updatedState.lastActivityTime == initialState.lastActivityTime)
    }
    
    @Test("given various session types, when updating, then state immutability is preserved")
    func test_sessionTypeImmutability() {
        let originalState = SessionInfo(id: 7777777777, type: .manual, isStart: true, lastActivityTime: 1111111111)
        let action = UpdateSessionTypeAction(sessionType: .automatic)
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.type == .manual) // Original state unchanged
        #expect(newState.type == .automatic) // New state has updated type
        #expect(newState.id == originalState.id)
        #expect(newState.isStart == originalState.isStart)
        #expect(newState.lastActivityTime == originalState.lastActivityTime)
    }
    
    // MARK: - UpdateSessionLastActivityAction Tests
    
    @Test("given various last activity times, when updating, then the new time is set", arguments: [
        UInt64(0),
        UInt64(1234567890),
        UInt64.max,
        UInt64(Date().timeIntervalSince1970 * 1000)
    ])
    func test_updateLastActivityTime(newActivityTime: UInt64) {
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
    func test_lastActivityTimeImmutability() {
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
    func test_endSession(testCase: SessionTestCase) {
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
    func test_endSessionCreatesNewInstance() {
        let originalState = SessionInfo(id: 1234567890, type: .manual, isStart: true, lastActivityTime: 9876543210)
        let action = EndSessionAction()
        
        let newState = action.reduce(currentState: originalState)
        
        #expect(originalState.id == 1234567890)
        #expect(originalState.type == .manual)
        #expect(originalState.isStart == true)
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
