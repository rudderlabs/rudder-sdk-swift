//
//  ResetUserIdentityActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 04/02/25.
//

import Testing
import Combine
import Foundation
@testable import RudderStackAnalytics

@Suite("ResetUserIdentityAction Tests")
struct ResetUserIdentityActionTests {
    
    // MARK: - Complete Reset Tests
    
    @Test("given user identity with all data, when resetting all entries, then all values are reset")
    func testResetActionResetsAllUserIdentityData() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe", "email": "john@example.com"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries())
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != originalAnonymousId, "Anonymous ID should be regenerated")
        #expect(result.anonymousId.isValidUUID, "New anonymous ID should be a valid UUID")
        #expect(result.userId.isEmpty, "User ID should be reset to empty")
        #expect(result.traits.isEmpty, "Traits should be reset to empty")
    }
    
    // MARK: - Selective Preservation Tests
    
    @Test("given user identity, when preserving anonymous ID only, then anonymous ID remains unchanged")
    func testResetActionPreservesAnonymousIdOnly() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId == originalAnonymousId, "Anonymous ID should be preserved")
        #expect(result.userId.isEmpty, "User ID should be reset")
        #expect(result.traits.isEmpty, "Traits should be reset")
    }
    
    @Test("given user identity, when preserving user ID only, then user ID remains unchanged")
    func testResetActionPreservesUserIdOnly() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(userId: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != originalAnonymousId, "Anonymous ID should be regenerated")
        #expect(result.userId == originalUserId, "User ID should be preserved")
        #expect(result.traits.isEmpty, "Traits should be reset")
    }
    
    @Test("given user identity, when preserving traits only, then traits remain unchanged")
    func testResetActionPreservesTraitsOnly() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe", "email": "john@example.com"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(traits: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != originalAnonymousId, "Anonymous ID should be regenerated")
        #expect(result.userId.isEmpty, "User ID should be reset")
        #expect(areTraitsEqual(result.traits, originalTraits), "Traits should be preserved")
    }
    
    // MARK: - Multiple Preservation Tests
    
    @Test("given user identity, when preserving anonymous ID and user ID, then both are preserved")
    func testResetActionPreservesAnonymousIdAndUserId() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(
            anonymousId: false,
            userId: false,
            traits: true,
            session: true
        ))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId == originalAnonymousId, "Anonymous ID should be preserved")
        #expect(result.userId == originalUserId, "User ID should be preserved")
        #expect(result.traits.isEmpty, "Traits should be reset")
    }
    
    @Test("given user identity, when preserving user ID and traits, then both are preserved")
    func testResetActionPreservesUserIdAndTraits() {
        let originalAnonymousId = "test-anonymous-id"
        let originalUserId = "test-user-id"
        let originalTraits = ["name": "John Doe", "company": "Example Inc"]
        
        let state = createState(initialState: createTestUserIdentity(
            anonymousId: originalAnonymousId,
            userId: originalUserId,
            traits: originalTraits
        ))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(
            anonymousId: true,
            userId: false,
            traits: false,
            session: true
        ))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != originalAnonymousId, "Anonymous ID should be regenerated")
        #expect(result.userId == originalUserId, "User ID should be preserved")
        #expect(areTraitsEqual(result.traits, originalTraits), "Traits should be preserved")
    }
    
    // MARK: - State Management Integration Tests
    
    @Test("given subscribed state, when resetting identity, then subscribers receive updates")
    func testResetActionNotifiesSubscribers() {
        let initialIdentity = createTestUserIdentity()
        let state = createState(initialState: initialIdentity)
        
        var receivedIdentities: [UserIdentity] = []
        var cancellables = Set<AnyCancellable>()
        
        state.state.sink { identity in
            receivedIdentities.append(identity)
        }.store(in: &cancellables)
        
        let action = ResetUserIdentityAction(entries: ResetEntries())
        state.dispatch(action: action)
        
        #expect(receivedIdentities.count == 2, "Should receive initial and updated identity")
        #expect(receivedIdentities[0].userId == "test-user-id", "First should be initial identity")
        #expect(receivedIdentities[1].userId.isEmpty, "Second should have reset user ID")
        #expect(receivedIdentities[1].anonymousId != receivedIdentities[0].anonymousId, "Anonymous ID should change")
    }
    
    // MARK: - Immutability Tests
    
    @Test("given original identity, when applying reset action, then original identity remains unchanged")
    func testResetActionMaintainsImmutability() {
        let originalIdentity = createTestUserIdentity()
        let originalAnonymousId = originalIdentity.anonymousId
        let originalUserId = originalIdentity.userId
        let originalTraits = originalIdentity.traits
        
        let action = ResetUserIdentityAction(entries: ResetEntries())
        _ = action.reduce(currentState: originalIdentity)
        
        #expect(originalIdentity.anonymousId == originalAnonymousId, "Original anonymous ID unchanged")
        #expect(originalIdentity.userId == originalUserId, "Original user ID unchanged")
        #expect(areTraitsEqual(originalIdentity.traits, originalTraits), "Original traits unchanged")
    }
}

// MARK: - Test Data Helpers using SwiftTestMockProvider

extension ResetUserIdentityActionTests {
    
    private func createTestUserIdentity(
        anonymousId: String = "test-anonymous-id",
        userId: String = "test-user-id",
        traits: [String: Any] = ["name": "John Doe", "email": "john@example.com"]
    ) -> UserIdentity {
        return UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits)
    }
    
    private func areTraitsEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (key, lhsValue) in lhs {
            guard let rhsValue = rhs[key] else { return false }
            
            // Compare based on type
            switch (lhsValue, rhsValue) {
            case (let l as String, let r as String): if l != r { return false }
            case (let l as Int, let r as Int): if l != r { return false }
            case (let l as Double, let r as Double): if l != r { return false }
            case (let l as Bool, let r as Bool): if l != r { return false }
            case (let l as [String: Any], let r as [String: Any]): if !areTraitsEqual(l, r) { return false }
            default: return false // Unsupported type or type mismatch
            }
        }
        return true
    }
}

// MARK: - Helper Extensions

private extension String {
    var isValidUUID: Bool {
        return UUID(uuidString: self) != nil
    }
}
