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
            
            let state = createState(initialState: SessionInfo(id: initialSessionId))
            let action = UpdateSessionIdAction(sessionId: expectedSessionId)
            
            when("Dispatching UpdateSessionIdAction") {
                state.dispatch(action: action)
                
                then("The sessionId should update to the new value") {
                    XCTAssertEqual(state.state.value.id, expectedSessionId)
                }
            }
        }
    }
    
    func test_updateIsSessionStartAction() {
        given("A SessionInfo state with an initial isStart value") {
            
            let initialIsSessionStart = false
            let expectedIsSessionStart = true
            
            let state = createState(initialState: SessionInfo(isStart: initialIsSessionStart))
            let action = UpdateIsSessionStartAction(isSessionStart: expectedIsSessionStart)
            
            when("Dispatching UpdateIsSessionStartAction") {
                state.dispatch(action: action)
                
                then("The isStart value should update to the new state") {
                    XCTAssertEqual(state.state.value.isStart, expectedIsSessionStart)
                }
            }
        }
    }
    
    func test_updateSessionTypeAction() {
        given("A SessionInfo state with an initial session type") {
            
            let initialSessionType: SessionType = .automatic
            let expectedSessionType: SessionType = .manual
            
            let state = createState(initialState: SessionInfo(type: initialSessionType))
            let action = UpdateSessionTypeAction(sessionType: expectedSessionType)
            
            when("Dispatching UpdateSessionTypeAction") {
                state.dispatch(action: action)
                
                then("The session type should update to the new value") {
                    XCTAssertEqual(state.state.value.type, expectedSessionType)
                }
            }
        }
    }
    
    func test_endSessionAction() {
        given("A SessionInfo state with an active session") {
            let state = createState(initialState: SessionInfo(id: 12342341234, type: .manual, isStart: true))
            let action = EndSessionAction()
            
            when("Dispatching EndSessionAction") {
                state.dispatch(action: action)
                
                then("SessionInfo should reset to default values") {
                    XCTAssertEqual(state.state.value.id, SessionConstants.defaultSessionId)
                    XCTAssertEqual(state.state.value.type, SessionConstants.defaultSessionType)
                    XCTAssertEqual(state.state.value.isStart, SessionConstants.defaultIsSessionStart)
                }
            }
        }
    }
}
