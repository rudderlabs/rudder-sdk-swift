//
//  AnonymousIdActionTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 15/01/25.
//

import XCTest
@testable import Analytics

final class AnonymousIdActionTests: XCTestCase {
    
    func test_updateAction() {
        given("Prepare test anonymous ID state and action..") {
            
            let initialAnonymousId = "initial_test_anonymous_id"
            let secondAnonymousId = "second_test_anonymous_id"
            
            let state = createState(initialState: UserIdentity(anonymousId: initialAnonymousId))
            let action = SetAnonymousIdAction(anonymousId: secondAnonymousId)
            
            when("Update state with action") {
                state.dispatch(action: action)
                
                then("UserIdentity initialized with storage values") {
                    XCTAssertEqual(state.state.value.anonymousId, secondAnonymousId, "The anonymousId should be updated to the new value.")
                }
            }
        }
    }
}
