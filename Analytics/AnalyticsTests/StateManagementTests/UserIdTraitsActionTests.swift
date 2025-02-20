//
//  UserIdTraitsActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 24/01/25.
//

import XCTest
@testable import Analytics

final class UserIdTraitsActionTests: XCTestCase {
    
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
    }
    
    func test_updateAction() {
        given("Prepare test UserIdentity state with initial set of values and action with expected set of values...") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let initialUserId = "initial_test_user_id"
            let initialTraits = ["initial_traits_key": "initial_traits_value"]
            
            let expectedUserId = "test-user-id"
            let expectedTraits = ["traits_key": "traits_value", "traits_key2": "sk@example.com"]
            
            let processingState = createState(initialState: UserIdentity(userId: initialUserId, traits: initialTraits))
            let action = SetUserIdAndTraitsAction(userId: expectedUserId, traits: expectedTraits, storage: storage)
            
            when("Update initial state of UserIdentity with expected values..") {
                processingState.dispatch(action: action)
                
                then("UserIdentity updated with expected values") {
                    XCTAssertEqual(processingState.state.value.userId, expectedUserId, "The userId should be updated to the new value.")
                    XCTAssertEqual(processingState.state.value.traits as? [String : String], expectedTraits, "The traits should be updated to the new value.")
                }
            }
        }
    }
    
    func test_updateAction_appendValues() {
        given("Prepare test UserIdentity state with first set of values..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let firstUserId = "first_test_user_id"
            let firstTraits = ["first_traits_key": "first_traits_value"]
            
            let secondTraits = ["traits_key": "traits_value", "traits_key2": "sk@example.com"]
            
            let processingState = createState(initialState: UserIdentity(userId: firstUserId, traits: firstTraits))
            
            when("Update current state of UserIdentity with added set of values and same userId...") {
                let newAction = SetUserIdAndTraitsAction(userId: firstUserId, traits: secondTraits, storage: storage)
                processingState.dispatch(action: newAction)
                
                then("UserIdentity updated with appended values...") {
                    XCTAssertEqual(processingState.state.value.traits as? [String : String], firstTraits + secondTraits, "The traits should be updated with the added values.")
                }
            }
        }
    }
}
