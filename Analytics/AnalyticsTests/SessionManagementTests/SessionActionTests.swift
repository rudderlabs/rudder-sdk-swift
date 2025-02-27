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
        given("Prepare test SessionInfo state with sessionId value and action..") {
            
            let initialSessionId: UInt64 = 12341231234
            let expectedSessionId: UInt64 = 43214324321
            
            let state = createState(initialState: SessionInfo(sessionId: initialSessionId))
            let action = UpdateSessionIdAction(sessionId: expectedSessionId)
            
            when("Update state of SessionInfo with expected session ID") {
                state.dispatch(action: action)
                
                then("SessionInfo updated with new session ID") {
                    XCTAssertEqual(state.state.value.sessionId, expectedSessionId)
                }
            }
        }
    }
    
    func test_updateIsSessionStartAction() {
        given("Prepare test SessionInfo state with isSessionStart value and action..") {
            
            let isSessionStart_first = false
            let isSessionStart_second = true
            
            let state = createState(initialState: SessionInfo(isSessionStart: isSessionStart_first))
            let action = UpdateIsSessionStartAction(isSessionStart: isSessionStart_second)
            
            when("Update state of SessionInfo with expected isSessionStart value") {
                state.dispatch(action: action)
                
                then("SessionInfo updated with new isSessionStart value") {
                    XCTAssertEqual(state.state.value.isSessionStart, isSessionStart_second)
                }
            }
        }
    }
    
    func test_updateSessionTypeAction() {
        given("Prepare test SessionInfo state with session type value and action..") {
            
            let initialSessionType: SessionType = .automatic
            let expectedSessionType: SessionType = .manual
            
            let state = createState(initialState: SessionInfo(sessionType: initialSessionType))
            let action = UpdateSessionTypeAction(sessionType: expectedSessionType)
            
            when("Update state of SessionInfo with expected session type") {
                state.dispatch(action: action)
                
                then("SessionInfo updated with new session type") {
                    XCTAssertEqual(state.state.value.sessionType, expectedSessionType)
                }
            }
        }
    }
    
    func test_endSessionAction() {
        given("Prepare test SessionInfo state with initial values and action..") {
            let state = createState(initialState: SessionInfo(sessionId: 12342341234, sessionType: .manual, isSessionStart: true))
            let action = EndSessionAction()
            
            when("Update state of SessionInfo with end session action") {
                state.dispatch(action: action)
                
                then("SessionInfo reset to default values") {
                    XCTAssertEqual(state.state.value.sessionId, SessionConstants.defaultSessionId)
                    XCTAssertEqual(state.state.value.sessionType, SessionConstants.defaultSessionType)
                    XCTAssertEqual(state.state.value.isSessionStart, SessionConstants.defaultIsSessionStart)
                }
            }
        }
    }
}
