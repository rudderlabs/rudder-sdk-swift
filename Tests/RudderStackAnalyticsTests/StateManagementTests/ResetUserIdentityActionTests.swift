//
//  ResetUserIdentityActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 04/02/25.
//

import Testing
@testable import RudderStackAnalytics

struct ResetUserIdentityActionTests {
    
    @Test
    func test_resetAction_resetsAllUserIdentityData() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries())
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    #expect(state.state.value.anonymousId != anonymousId, "Anonymous ID should be regenerated")
                    #expect(state.state.value.userId.isEmpty, "User ID should be reset")
                    #expect(state.state.value.traits.isEmpty, "Traits should be reset")
                }
            }
        }
    }
    
    @Test
    func test_resetAction_preservesAnonymousIdOnly() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except anonymousId..") {
                    #expect(state.state.value.anonymousId == anonymousId, "Anonymous ID should not be regenerated")
                    #expect(state.state.value.userId.isEmpty, "User ID should be reset")
                    #expect(state.state.value.traits.isEmpty, "Traits should be reset")
                }
            }
        }
    }
    
    @Test
    func test_resetAction_preservesUserIdOnly() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(userId: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except userId..") {
                    #expect(state.state.value.anonymousId != anonymousId, "Anonymous ID should be regenerated")
                    #expect(!state.state.value.userId.isEmpty, "User ID should not be reset")
                    #expect(state.state.value.traits.isEmpty, "Traits should be reset")
                }
            }
        }
    }
    
    @Test
    func test_resetAction_preservesTraitsOnly() {
        given("Prepare a test user identity reference with a reset action...") {
            let anonymousId = "testAnonymousId"
            let userId = "testUserId"
            let traits = ["testKey": "testValue"]
            
            let state = createState(initialState: UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits))
            let action = ResetUserIdentityAction(entries: ResetEntries(traits: false))
            when("Update state with action..") {
                state.dispatch(action: action)
                
                then("UserIdentity values are reset except traits..") {
                    #expect(state.state.value.anonymousId != anonymousId, "Anonymous ID should be regenerated")
                    #expect(state.state.value.userId.isEmpty, "User ID should be reset")
                    #expect(!state.state.value.traits.isEmpty, "Traits should not be reset")
                }
            }
        }
    }
}
