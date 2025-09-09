//
//  ResetUserIdentityActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 04/02/25.
//

import XCTest
@testable import RudderStackAnalytics

final class ResetUserIdentityActionTests: XCTestCase {
    
    func test_resetAction() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries())
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    XCTAssertNotEqual(state.state.value.anonymousId, anonymousId, "Anonymous ID should be regenerated")
                    XCTAssertTrue(state.state.value.userId.isEmpty)
                    XCTAssertTrue(state.state.value.traits.isEmpty)
                }
            }
        }
    }
    
    func test_reset_anonymousId_action() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    XCTAssertEqual(state.state.value.anonymousId, anonymousId, "Anonymous ID should not be regenerated")
                    XCTAssertTrue(state.state.value.userId.isEmpty)
                    XCTAssertTrue(state.state.value.traits.isEmpty)
                }
            }
        }
    }
    
    func test_reset_userId_action() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(userId: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    XCTAssertNotEqual(state.state.value.anonymousId, anonymousId, "Anonymous ID should be regenerated")
                    XCTAssertFalse(state.state.value.userId.isEmpty)
                    XCTAssertTrue(state.state.value.traits.isEmpty)
                }
            }
        }
    }
    
    func test_reset_traits_action() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(traits: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    XCTAssertNotEqual(state.state.value.anonymousId, anonymousId, "Anonymous ID should be regenerated")
                    XCTAssertTrue(state.state.value.userId.isEmpty)
                    XCTAssertFalse(state.state.value.traits.isEmpty)
                }
            }
        }
    }
}
