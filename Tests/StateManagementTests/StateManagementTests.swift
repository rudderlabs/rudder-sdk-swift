//
//  StateManagementTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 07/01/25.
//

import XCTest
import Combine
@testable import RudderStackAnalytics

final class StateManagementTests: XCTestCase {
    
    func test_createState() {
        given("Initial State of Int type") {
            let value: Int = 1
            
            when("Create a state with given type") {
                let stateInstance = createState(initialState: value)
                
                then("State type should be equal to initial state type") {
                    XCTAssert(type(of: value) == type(of: stateInstance.state.value))
                }
            }
        }
    }
    
    func test_mockActionUpdatesState() {
        given("A State with an initial state of 0") {
            let stateInstance = createState(initialState: 0)
            
            when("Create a mock action that adds 5 to the current state and dispatch it") {
                let mockAction = MockStateAction<Int> { currentState in
                    currentState + 5
                }
                
                stateInstance.dispatch(action: mockAction)
                
                then("The state should be updated to 5") {
                    XCTAssertEqual(stateInstance.state.value, 5)
                }
            }
        }
    }
    
    func test_multipleMockActionsUpdatesState() {
        given("A State with an initial state of 0") {
            let stateInstance = createState(initialState: 0)
            
            when("Create multiple mock actions that adds 5 to the current state and dispatch them") {
                let mockAction1 = MockStateAction<Int> { currentState in
                    currentState + 5
                }
                
                let mockAction2 = MockStateAction<Int> { currentState in
                    currentState + 15
                }
                
                let mockAction3 = MockStateAction<Int> { currentState in
                    currentState - 8
                }
                
                stateInstance.dispatch(action: mockAction1)
                stateInstance.dispatch(action: mockAction2)
                stateInstance.dispatch(action: mockAction3)
                
                then("The state should be updated to 12") {
                    XCTAssertEqual(stateInstance.state.value, 12)
                }
            }
        }
    }
    
    func test_mockActionSubscriptionUpdatesState() {
        given("A State with an initial state of 0") {
            let stateInstance = createState(initialState: 0)
            
            var cancellables = Set<AnyCancellable>()

            var updatedValue = 0
            
            stateInstance.state.sink { newValue in
                updatedValue = newValue
            }.store(in: &cancellables)
            
            when("Create a mock action subscription that adds 5 to the current state") {
                let mockAction1 = MockStateAction<Int> { currentState in
                    currentState + 15
                }
                
                let mockAction2 = MockStateAction<Int> { currentState in
                    currentState - 5
                }
                
                stateInstance.dispatch(action: mockAction1)
                stateInstance.dispatch(action: mockAction2)
                
                then("The state should be updated to 10") {
                    XCTAssertEqual(updatedValue, 10)
                }
            }
        }
    }
}
