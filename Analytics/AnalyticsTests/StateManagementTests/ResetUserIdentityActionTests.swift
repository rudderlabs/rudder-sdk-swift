//
//  ResetUserIdentityActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 04/02/25.
//

import XCTest
@testable import Analytics

final class ResetUserIdentityActionTests: XCTestCase {
    
    func test_resetAction_withoutAnonymousId() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(clearAnonymousId: false)
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    XCTAssertEqual(state.state.value.anonymousId, anonymousId)
                    XCTAssertTrue(state.state.value.userId.isEmpty)
                    XCTAssertTrue(state.state.value.traits.isEmpty)
                }
            }
        }
    }
    
    func test_resetAction_withAnonymousId() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(clearAnonymousId: true)
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity all values are reseted..") {
                    XCTAssertNotEqual(state.state.value.anonymousId, anonymousId)
                    XCTAssertTrue(state.state.value.userId.isEmpty)
                    XCTAssertTrue(state.state.value.traits.isEmpty)
                }
            }
        }
    }
}
