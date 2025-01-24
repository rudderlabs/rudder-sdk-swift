//
//  UserIdentityTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 08/01/25.
//

import Foundation
import XCTest
@testable import Analytics

final class UserIdentityTests: XCTestCase {
    
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
    }
    
    func test_initializeState_emptyStorage() {
        given("Prepare empty storage..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            when("UserIdentity initialized using empty storage.") {
                let userIdentity = UserIdentity.initializeState(storage)
                
                then("UserIdentity initialized with default values") {
                    XCTAssertFalse(userIdentity.anonymousId.isEmpty, "Anonymous ID should be generated")
                    XCTAssertEqual(userIdentity.userId, "", "User ID should be empty")
                    XCTAssertTrue(userIdentity.traits.isEmpty, "Traits should be empty by default")
                    XCTAssertTrue(userIdentity.externalIds.isEmpty, "External IDs should be empty by default")
                }
            }
        }
    }
    
    func test_initializeState_notEmptyStorage() {
        given("Prepare storage with values..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let expectedAnonymousId = "test-anonymous-id"
            let expectedUserId = "test-user-id"
            let expectedTraits = ["traits_key": "traits_value", "traits_key2": "sk@example.com"]
            let externalIds = [ExternalId(type: "sample_type", id: "sample_id")]
            
            storage.write(value: expectedAnonymousId, key: StorageKeys.anonymousId)
            storage.write(value: expectedUserId, key: StorageKeys.userId)
            storage.write(value: expectedTraits.jsonString, key: StorageKeys.traits)
            
            let externalIdStrings = externalIds.compactMap { $0.jsonString }
            storage.write(value: externalIdStrings, key: StorageKeys.externalIds)
            
            when("UserIdentity initialized.") {
                let userIdentity = UserIdentity.initializeState(storage)
                
                then("UserIdentity initialized with storage values") {
                    XCTAssertEqual(userIdentity.anonymousId, expectedAnonymousId, "Anonymous ID should match stored value")
                    XCTAssertEqual(userIdentity.userId, expectedUserId, "User ID should match stored value")
                    XCTAssertEqual((userIdentity.traits["traits_key2"] as? String ?? ""), "sk@example.com", "Traits should match stored value")
                    XCTAssertEqual(userIdentity.externalIds.count, 1, "There should be one external ID")
                    XCTAssertEqual(userIdentity.externalIds.first?.type, "sample_type", "External ID type should match")
                    XCTAssertEqual(userIdentity.externalIds.first?.id, "sample_id", "External ID value should match")
                }
            }
        }
    }
}
