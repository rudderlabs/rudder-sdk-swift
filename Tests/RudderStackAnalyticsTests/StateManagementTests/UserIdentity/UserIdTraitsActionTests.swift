//
//  UserIdTraitsActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 24/01/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SetUserIdAndTraitsAction Tests")
struct UserIdTraitsActionTests {
    
    // MARK: - Basic Functionality Tests
    
    @Test("given user identity with initial values, when setting new user ID and traits, then both are updated")
    func testSetUserIdAndTraitsActionUpdatesUserIdAndTraits() {
        let storage = MockKeyValueStorage()
        let initialUserId = "initial_test_user_id"
        let initialTraits = ["initial_traits_key": "initial_traits_value"]
        
        let expectedUserId = "test-user-id"
        let expectedTraits = ["traits_key": "traits_value", "traits_key2": "test@example.com"]
        
        let processingState = createState(initialState: UserIdentity(userId: initialUserId, traits: initialTraits))
        
        let action = SetUserIdAndTraitsAction(userId: expectedUserId, traits: expectedTraits, storage: storage)
        processingState.dispatch(action: action)
        
        #expect(processingState.state.value.userId == expectedUserId, "The userId should be updated to the new value.")
        #expect(processingState.state.value.traits.count == expectedTraits.count, "The traits should be updated to the new values.")
    }
    
    @Test("given user identity with existing traits, when setting same user ID with new traits, then traits are merged")
    func testSetUserIdAndTraitsActionMergesTraits() {
        let storage = MockKeyValueStorage()
        let firstUserId = "first_test_user_id"
        let firstTraits = ["first_traits_key": "first_traits_value"]
        let secondTraits = ["traits_key": "traits_value", "traits_key2": "test@example.com"]
        
        let processingState = createState(initialState: UserIdentity(userId: firstUserId, traits: firstTraits))
        
        let newAction = SetUserIdAndTraitsAction(userId: firstUserId, traits: secondTraits, storage: storage)
        processingState.dispatch(action: newAction)
        
        let resultTraits = processingState.state.value.traits
        #expect(resultTraits.count == 3, "Should have merged traits from both sets")
        #expect(processingState.state.value.userId == firstUserId, "User ID should remain the same")
    }
    
    @Test("given user identity, when setting empty user ID and empty traits, then values are updated to empty")
    func testSetUserIdAndTraitsActionHandlesEmptyValues() {
        let storage = MockKeyValueStorage()
        let initialUserId = "existing_user_id"
        let initialTraits = ["existing_key": "existing_value"]
        
        let processingState = createState(initialState: UserIdentity(userId: initialUserId, traits: initialTraits))
        
        let action = SetUserIdAndTraitsAction(userId: "", traits: [:], storage: storage)
        processingState.dispatch(action: action)
        
        #expect(processingState.state.value.userId.isEmpty, "User ID should be empty")
        #expect(processingState.state.value.traits.isEmpty, "Traits should be empty")
    }
    
    @Test("given user identity with anonymous ID, when setting user ID and traits, then anonymous ID is preserved")
    func testSetUserIdAndTraitsActionPreservesAnonymousId() {
        let storage = MockKeyValueStorage()
        let originalAnonymousId = "original_anonymous_id"
        let originalIdentity = UserIdentity(
            anonymousId: originalAnonymousId,
            userId: "old_user_id",
            traits: ["old_key": "old_value"]
        )
        
        let processingState = createState(initialState: originalIdentity)
        
        let newUserId = "new_user_id"
        let newTraits = ["new_key": "new_value"]
        let action = SetUserIdAndTraitsAction(userId: newUserId, traits: newTraits, storage: storage)
        processingState.dispatch(action: action)
        
        let result = processingState.state.value
        #expect(result.anonymousId == originalAnonymousId, "Anonymous ID should be preserved")
        #expect(result.userId == newUserId, "User ID should be updated")
        #expect(result.traits.count == newTraits.count, "Traits should be updated")
    }
    
    // MARK: - State Management Integration Tests
    
    @Test("given state instance, when dispatching set user ID and traits action, then state management integration works")
    func testSetUserIdAndTraitsActionWithStateManagement() {
        let storage = MockKeyValueStorage()
        let initialIdentity = UserIdentity(userId: "initial_id", traits: ["initial": "value"])
        let state = createState(initialState: initialIdentity)
        
        let newUserId = "updated_id"
        let newTraits = ["updated": "value", "another": "trait"]
        let action = SetUserIdAndTraitsAction(userId: newUserId, traits: newTraits, storage: storage)
        state.dispatch(action: action)
        
        let currentState = state.state.value
        #expect(currentState.userId == newUserId, "State should reflect the updated user ID")
        #expect(currentState.traits.count == newTraits.count, "State should reflect the updated traits")
    }
    
    // MARK: - Immutability Tests
    
    @Test("given original identity, when applying set user ID and traits action, then original identity remains unchanged")
    func testSetUserIdAndTraitsActionMaintainsImmutability() {
        let storage = MockKeyValueStorage()
        let originalUserId = "original_id"
        let originalTraits = ["original": "traits"]
        let originalIdentity = UserIdentity(userId: originalUserId, traits: originalTraits)
        
        let action = SetUserIdAndTraitsAction(userId: "new_id", traits: ["new": "traits"], storage: storage)
        _ = action.reduce(currentState: originalIdentity)
        
        #expect(originalIdentity.userId == originalUserId, "Original user ID should not be modified")
        #expect(originalIdentity.traits.count == originalTraits.count, "Original traits should not be modified")
    }
}
