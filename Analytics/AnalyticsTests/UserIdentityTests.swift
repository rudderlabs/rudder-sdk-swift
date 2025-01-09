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
                }
            }
        }
    }
    
    func test_initializeState_notEmptyStorage() {
        given("Prepare storage with values..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let expectedAnonymousId = "test-anonymous-id"
            
            when("UserIdentity initialized.") {
                let userIdentity = UserIdentity.initializeState(storage)
                
                then("UserIdentity initialized with storage values") {
                    XCTAssertEqual(userIdentity.anonymousId, expectedAnonymousId, "Anonymous ID should match stored value")
                }
            }
        }
    }
}
