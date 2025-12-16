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
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries())
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != testAnonymousId, "\(anonymousIdRegeneratedMessage)")
        #expect(result.anonymousId.isValidUUID, "New anonymous ID should be a valid UUID")
        #expect(result.userId.isEmpty, "User ID should be reset to empty")
        #expect(result.traits.isEmpty, "Traits should be reset to empty")
    }
    
    // MARK: - Selective Preservation Tests
    
    @Test("given user identity, when preserving anonymous ID only, then anonymous ID remains unchanged")
    func testResetActionPreservesAnonymousIdOnly() {
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId == testAnonymousId, "Anonymous ID should be preserved")
        #expect(result.userId.isEmpty, "User ID should be reset")
        #expect(result.traits.isEmpty, "\(traitsResetMessage)")
    }
    
    @Test("given user identity, when preserving user ID only, then user ID remains unchanged")
    func testResetActionPreservesUserIdOnly() {
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(userId: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != testAnonymousId, "\(anonymousIdRegeneratedMessage)")
        #expect(result.userId == testUserId, "\(userIdPreservedMessage)")
        #expect(result.traits.isEmpty, "\(traitsResetMessage)")
    }
    
    @Test("given user identity, when preserving traits only, then traits remain unchanged")
    func testResetActionPreservesTraitsOnly() {
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(traits: false))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != testAnonymousId, "\(anonymousIdRegeneratedMessage)")
        #expect(result.userId.isEmpty, "User ID should be reset")
        #expect(areTraitsEqual(result.traits, testTraits), "Traits should be preserved")
    }
    
    // MARK: - Multiple Preservation Tests
    
    @Test("given user identity, when preserving anonymous ID and user ID, then both are preserved")
    func testResetActionPreservesAnonymousIdAndUserId() {
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: false, userId: false, traits: true, session: true))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId == testAnonymousId, "Anonymous ID should be preserved")
        #expect(result.userId == testUserId, "\(userIdPreservedMessage)")
        #expect(result.traits.isEmpty, "\(traitsResetMessage)")
    }
    
    @Test("given user identity, when preserving user ID and traits, then both are preserved")
    func testResetActionPreservesUserIdAndTraits() {
        let state = createState(initialState: createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits))
        
        let action = ResetUserIdentityAction(entries: ResetEntries(anonymousId: true, userId: false, traits: false, session: true))
        state.dispatch(action: action)
        
        let result = state.state.value
        #expect(result.anonymousId != testAnonymousId, "\(anonymousIdRegeneratedMessage)")
        #expect(result.userId == testUserId, "\(userIdPreservedMessage)")
        #expect(areTraitsEqual(result.traits, testTraits), "Traits should be preserved")
    }
    
    // MARK: - State Management Integration Tests
    
    @Test("given subscribed state, when resetting identity, then subscribers receive updates")
    func testResetActionNotifiesSubscribers() {
        let initialIdentity = createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits)
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
        let originalIdentity = createTestUserIdentity(anonymousId: testAnonymousId, userId: testUserId, traits: testTraits)
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

// MARK: - Test Data Helpers using MockProvider

extension ResetUserIdentityActionTests {
    
    private func createTestUserIdentity(anonymousId: String, userId: String, traits: [String: Any]) -> UserIdentity {
        return UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits)
    }
    
    private func areTraitsEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        for (key, lhsValue) in lhs {
            guard let rhsValue = rhs[key],
                  areValuesEqual(lhsValue, rhsValue) else {
                return false
            }
        }
        
        return true
    }

    private func areValuesEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        switch (lhs, rhs) {
        case (let l as String, let r as String): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Bool, let r as Bool): return l == r
        case (let l as [String: Any], let r as [String: Any]): return areTraitsEqual(l, r)
        default: return false
        }
    }
    
    private var testAnonymousId: String { "test-anonymous-id" }
    private var testUserId: String { "test-user-id" }
    private var testTraits: [String: Any] { ["name": "John Doe", "email": "john@example.com"] }
    
    // Test assertion messages
    private var anonymousIdRegeneratedMessage: String { "Anonymous ID should be regenerated" }
    private var traitsResetMessage: String { "Traits should be reset" }
    private var userIdPreservedMessage: String { "User ID should be preserved" }
}

// MARK: - Helper Extensions

private extension String {
    var isValidUUID: Bool {
        return UUID(uuidString: self) != nil
    }
}
