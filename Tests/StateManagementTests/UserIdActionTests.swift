//
//  UserIdActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 01/02/25.
//

import XCTest
@testable import Analytics

final class UserIdActionTests: XCTestCase {
    
    func test_updateAction() {
        given("Prepare test user ID state and action..") {
            
            let initialUserId = "initial_test_user_id"
            let secondUserId = "second_test_user_id"
            
            let state = createState(initialState: UserIdentity(userId: initialUserId))
            let action = SetUserIdAction(userId: secondUserId)
            
            when("Update state of UserIdentity with second user ID") {
                state.dispatch(action: action)
                
                then("UserIdentity updated with new user ID") {
                    XCTAssertEqual(state.state.value.userId, secondUserId, "The user ID should be updated to the new value.")
                }
            }
        }
    }
}

