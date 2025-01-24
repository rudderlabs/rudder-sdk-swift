//
//  UserIdTraitsExternalIdsActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 24/01/25.
//

import XCTest
@testable import Analytics

final class UserIdTraitsExternalIdsActionTests: XCTestCase {
    
    private var storage: MockKeyValueStorage?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        storage = MockKeyValueStorage()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        storage = nil
    }
    
    func test_updateAction_singleUserId() {
        given("Prepare test anonymous ID state and action..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let initialUserId = "initial_test_user_id"
            let initialTraits = ["initial_traits_key": "initial_traits_value"]
            let initialExternalIds = [ExternalId(type: "initial_sample_type", id: "initial_sample_id")]
            
            let expectedUserId = "test-user-id"
            let expectedTraits = ["traits_key": "traits_value", "traits_key2": "sk@example.com"]
            let expectedExternalIds = [ExternalId(type: "sample_type", id: "sample_id")]
            
            let state = createState(initialState: UserIdentity(userId: initialUserId, traits: initialTraits, externalIds: initialExternalIds))
            let action = SetUserIdTraitsAndExternalIdsAction(userId: expectedUserId, traits: expectedTraits, externalIds: expectedExternalIds, storage: storage)
            
            when("Update state with action") {
                state.dispatch(action: action)
                
                then("UserIdentity updated with expected values") {
                    XCTAssertEqual(state.state.value.userId, expectedUserId, "The userId should be updated to the new value.")
                    XCTAssertEqual(state.state.value.traits["traits_key2"] as? String, expectedTraits["traits_key2"], "The traits should be updated to the new value.")
                    XCTAssertEqual(state.state.value.externalIds[0].id, expectedExternalIds[0].id, "The externalIds should be updated to the new value.")
                }
            }
        }
    }
    
    func test_updateAction_appendValues() {
        given("Prepare test anonymous ID state and action..") {
            guard let storage else { XCTFail("Storage is not initialized."); return }
            
            let firstUserId = "first_test_user_id"
            let firstTraits = ["first_traits_key": "first_traits_value"]
            let firstExternalIds = [ExternalId(type: "first_sample_type", id: "first_sample_id")]
            
            let secondUserId = "test-user-id"
            let secondTraits = ["traits_key": "traits_value", "traits_key2": "sk@example.com"]
            let secondExternalIds = [ExternalId(type: "sample_type", id: "sample_id")]
            
            let state = createState(initialState: UserIdentity(userId: firstUserId, traits: firstTraits, externalIds: firstExternalIds))
            let action = SetUserIdTraitsAndExternalIdsAction(userId: secondUserId, traits: secondTraits, externalIds: secondExternalIds, storage: storage)
            
            when("Update state with action") {
                state.dispatch(action: action)
                
                then("UserIdentity updated with expected values") {
                    XCTAssertEqual(state.state.value.userId, secondUserId, "The userId should be updated to the new value.")
                    XCTAssertEqual(state.state.value.traits["traits_key2"] as? String, secondTraits["traits_key2"], "The traits should be updated to the new value.")
                    XCTAssertEqual(state.state.value.externalIds[0].id, secondExternalIds[0].id, "The externalIds should be updated to the new value.")
                }
                
                when("append the values with same userId..") {
                    let newAction = SetUserIdTraitsAndExternalIdsAction(userId: secondUserId, traits: firstTraits, externalIds: firstExternalIds, storage: storage)
                    
                    when("Update state with action") {
                        state.dispatch(action: newAction)
                        
                        then("UserIdentity updated with expected values") {
                            XCTAssertEqual(state.state.value.userId, secondUserId, "The userId should be updated to the new value.")
                            XCTAssertEqual(state.state.value.traits["first_traits_key"] as? String, firstTraits["first_traits_key"], "The traits should be updated to the new value.")
                            XCTAssertEqual(state.state.value.externalIds[1].id, firstExternalIds[0].id, "The externalIds should be updated to the new value.")
                        }
                    }
                }
            }
        }
    }
}
