//
//  UserIdentityTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 08/01/25.
//

import Foundation
import XCTest
@testable import RudderStackAnalytics

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
                }
            }
        }
    }
    
    func test_initializeState_notEmptyStorage() {
        given("Prepare storage with values..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let expectedAnonymousId = "test-anonymous-id"
            let expectedUserId = "test-user-id"
            let expectedTraits = ["traits_key": "traits_value", "traits_key2": "test@example.com"]
            
            storage.write(value: expectedAnonymousId, key: Constants.storageKeys.anonymousId)
            storage.write(value: expectedUserId, key: Constants.storageKeys.userId)
            storage.write(value: expectedTraits.jsonString, key: Constants.storageKeys.traits)
            
            when("UserIdentity initialized.") {
                let userIdentity = UserIdentity.initializeState(storage)
                
                then("UserIdentity initialized with storage values") {
                    XCTAssertEqual(userIdentity.anonymousId, expectedAnonymousId, "Anonymous ID should match stored value")
                    XCTAssertEqual(userIdentity.userId, expectedUserId, "User ID should match stored value")
                    XCTAssertEqual(userIdentity.traits as? [String: String], expectedTraits, "Traits should match stored value")
                }
            }
        }
    }
}
