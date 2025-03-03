//
//  SessionActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Foundation
import XCTest
@testable import Analytics

final class SessionActionTests: XCTestCase {
    
    func test_updateSessionIdAction() {
        given("A SessionInfo state with an initial sessionId") {
            
            let initialSessionId: UInt64 = 12341231234
            let expectedSessionId: UInt64 = 43214324321
            
            let state = createState(initialState: SessionInfo(sessionId: initialSessionId))
            let action = UpdateSessionIdAction(sessionId: expectedSessionId)
            
            when("Dispatching UpdateSessionIdAction") {
                state.dispatch(action: action)
                
                then("The sessionId should update to the new value") {
                    XCTAssertEqual(state.state.value.sessionId, expectedSessionId)
                }
            }
        }
    }
    
    func test_updateIsSessionStartAction() {
        given("A SessionInfo state with an initial isSessionStart value") {
            
            let initialIsSessionStart = false
            let expectedIsSessionStart = true
            
            let state = createState(initialState: SessionInfo(isSessionStart: initialIsSessionStart))
            let action = UpdateIsSessionStartAction(isSessionStart: expectedIsSessionStart)
            
            when("Dispatching UpdateIsSessionStartAction") {
                state.dispatch(action: action)
                
                then("The isSessionStart value should update to the new state") {
                    XCTAssertEqual(state.state.value.isSessionStart, expectedIsSessionStart)
                }
            }
        }
    }
    
    func test_updateSessionTypeAction() {
        given("A SessionInfo state with an initial session type") {
            
            let initialSessionType: SessionType = .automatic
            let expectedSessionType: SessionType = .manual
            
            let state = createState(initialState: SessionInfo(sessionType: initialSessionType))
            let action = UpdateSessionTypeAction(sessionType: expectedSessionType)
            
            when("Dispatching UpdateSessionTypeAction") {
                state.dispatch(action: action)
                
                then("The session type should update to the new value") {
                    XCTAssertEqual(state.state.value.sessionType, expectedSessionType)
                }
            }
        }
    }
    
    func test_endSessionAction() {
        given("A SessionInfo state with an active session") {
            let state = createState(initialState: SessionInfo(sessionId: 12342341234, sessionType: .manual, isSessionStart: true))
            let action = EndSessionAction()
            
            when("Dispatching EndSessionAction") {
                state.dispatch(action: action)
                
                then("SessionInfo should reset to default values") {
                    XCTAssertEqual(state.state.value.sessionId, SessionConstants.defaultSessionId)
                    XCTAssertEqual(state.state.value.sessionType, SessionConstants.defaultSessionType)
                    XCTAssertEqual(state.state.value.isSessionStart, SessionConstants.defaultIsSessionStart)
                }
            }
        }
    }
}
