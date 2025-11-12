//
//  UserIdentityTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 08/01/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("UserIdentity Tests")
struct UserIdentityTests {
    
    // MARK: - Initialization Tests
    
    @Test("given empty storage, when initializing user identity, then default values are used")
    func testInitializeStateWithEmptyStorage() {
        let storage = MockKeyValueStorage()
        
        let userIdentity = UserIdentity.initializeState(storage)
        
        #expect(!userIdentity.anonymousId.isEmpty, "Anonymous ID should be generated")
        #expect(userIdentity.userId.isEmpty, "User ID should be empty")
        #expect(userIdentity.traits.isEmpty, "Traits should be empty by default")
    }
    
    @Test("given storage with user identity data, when initializing, then stored values are used")
    func testInitializeStateWithStoredData() {
        let storage = MockKeyValueStorage()
        let expectedAnonymousId = "test-anonymous-id"
        let expectedUserId = "test-user-id"
        let expectedTraits = ["name": "John Doe", "email": "test@example.com"]
        
        storage.write(value: expectedAnonymousId, key: Constants.storageKeys.anonymousId)
        storage.write(value: expectedUserId, key: Constants.storageKeys.userId)
        storage.write(value: expectedTraits.jsonString, key: Constants.storageKeys.traits)
        
        let userIdentity = UserIdentity.initializeState(storage)
        
        #expect(userIdentity.anonymousId == expectedAnonymousId, "Anonymous ID should match stored value")
        #expect(userIdentity.userId == expectedUserId, "User ID should match stored value")
        #expect(userIdentity.traits.count == expectedTraits.count, "Traits should match stored values")
    }
    
    @Test("given partial storage data, when initializing, then stored values are used with defaults for missing")
    func testInitializeStateWithPartialStoredData() {
        let storage = MockKeyValueStorage()
        let expectedUserId = "stored-user-id"
        
        storage.write(value: expectedUserId, key: Constants.storageKeys.userId)
        
        let userIdentity = UserIdentity.initializeState(storage)
        
        #expect(!userIdentity.anonymousId.isEmpty, "Anonymous ID should be generated even if not stored")
        #expect(userIdentity.userId == expectedUserId, "User ID should match stored value")
        #expect(userIdentity.traits.isEmpty, "Traits should be empty when not stored")
    }
    
    // MARK: - UserIdentity Creation Tests
    
    @Test("given user identity parameters, when creating user identity, then all properties are set correctly")
    func testUserIdentityCreation() {
        let anonymousId = "test-anonymous-id"
        let userId = "test-user-id"
        let traits = ["name": "Jane Doe", "age": 25] as [String: Any]
        
        let userIdentity = UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits)
        
        #expect(userIdentity.anonymousId == anonymousId, "Anonymous ID should be set")
        #expect(userIdentity.userId == userId, "User ID should be set")
        #expect(userIdentity.traits.count == traits.count, "Traits should be set")
    }
    
    @Test("given minimal parameters, when creating user identity, then optional properties use defaults")
    func testUserIdentityCreationWithDefaults() {
        let anonymousId = "test-anonymous-id"
        
        let userIdentity = UserIdentity(anonymousId: anonymousId)
        
        #expect(userIdentity.anonymousId == anonymousId, "Anonymous ID should be set")
        #expect(userIdentity.userId.isEmpty, "User ID should default to empty")
        #expect(userIdentity.traits.isEmpty, "Traits should default to empty")
    }
    
    // MARK: - Storage Key Tests
    
    @Test("given corrupted traits data in storage, when initializing, then traits default to empty")
    func testInitializeStateWithCorruptedTraitsData() {
        let storage = MockKeyValueStorage()
        let validAnonymousId = "valid-anonymous-id"
        let invalidTraitsJson = "invalid-json-data"
        
        storage.write(value: validAnonymousId, key: Constants.storageKeys.anonymousId)
        storage.write(value: invalidTraitsJson, key: Constants.storageKeys.traits)
        
        let userIdentity = UserIdentity.initializeState(storage)
        
        #expect(userIdentity.anonymousId == validAnonymousId, "Valid anonymous ID should be preserved")
        #expect(userIdentity.traits.isEmpty, "Corrupted traits should default to empty")
    }
}
