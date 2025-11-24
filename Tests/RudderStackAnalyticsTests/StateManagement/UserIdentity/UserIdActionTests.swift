//
//  UserIdActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 01/02/25.
//

import Testing
import Combine
@testable import RudderStackAnalytics

@Suite("SetUserIdAction Tests")
struct UserIdActionTests {
    
    @Test("given user identity with initial user ID, when setting new user ID, then user ID is updated")
    func testSetUserIdActionUpdatesUserId() {
        let initialUserId = "initial_test_user_id"
        let newUserId = "second_test_user_id"
        let state = createState(initialState: UserIdentity(userId: initialUserId))
        
        let action = SetUserIdAction(userId: newUserId)
        state.dispatch(action: action)
        
        #expect(state.state.value.userId == newUserId, "The user ID should be updated to the new value.")
    }
    
    @Test("given user identity, when setting empty user ID, then user ID becomes empty")
    func testSetUserIdActionHandlesEmptyUserId() {
        let state = createState(initialState: UserIdentity(userId: "existing_user_id"))
        
        let action = SetUserIdAction(userId: "")
        state.dispatch(action: action)
        
        #expect(state.state.value.userId.isEmpty, "User ID should be set to empty string")
    }
    
    @Test("given user identity with all properties, when setting user ID, then other properties are preserved")
    func testSetUserIdActionPreservesOtherProperties() {
        let originalAnonymousId = "test_anonymous_id"
        let originalTraits = ["name": "John Doe", "email": "john@example.com"]
        let initialIdentity = UserIdentity(
            anonymousId: originalAnonymousId,
            userId: "original_user_id",
            traits: originalTraits
        )
        let state = createState(initialState: initialIdentity)
        
        let newUserId = "new_user_id"
        let action = SetUserIdAction(userId: newUserId)
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.userId == newUserId, "User ID should be updated")
        #expect(result.anonymousId == originalAnonymousId, "Anonymous ID should be preserved")
        #expect(result.traits.count == originalTraits.count, "Traits should be preserved")
    }
    
    @Test("given state instance, when dispatching set user ID action, then state management integration works")
    func testSetUserIdActionWithStateManagement() {
        let initialIdentity = UserIdentity(userId: "initial_id")
        let state = createState(initialState: initialIdentity)
        
        let newUserId = "updated_id"
        let action = SetUserIdAction(userId: newUserId)
        state.dispatch(action: action)
        
        let currentState = state.state.value
        #expect(currentState.userId == newUserId, "State should reflect the updated user ID")
    }
    
    @Test("given original identity, when applying set user ID action, then original identity remains unchanged")
    func testSetUserIdActionMaintainsImmutability() {
        let originalUserId = "original_id"
        let originalIdentity = UserIdentity(userId: originalUserId)
        
        let action = SetUserIdAction(userId: "new_id")
        _ = action.reduce(currentState: originalIdentity)
        
        #expect(originalIdentity.userId == originalUserId, "Original identity should not be modified")
    }
}
