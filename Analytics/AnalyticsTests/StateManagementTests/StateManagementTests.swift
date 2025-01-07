//
//  StateManagementTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 07/01/25.
//

import XCTest
import Combine
@testable import Analytics

final class StateManagementTests: XCTestCase {
    
    func test_createFlowState() {
        given("Initial State of Int type") {
            let value: Int = 1
            
            when("Create a state with given type") {
                let flowState = createFlowState(initialState: value)
                
                then("State type should be equal to initial state type") {
                    XCTAssert(type(of: value) == type(of: flowState.state.value))
                }
            }
        }
    }
    
    func test_mockActionUpdatesState() {
        given("A FlowState with an initial state of 0") {
            let flowState = createFlowState(initialState: 0)
            
            when("Create a mock action that adds 5 to the current state and dispatch it") {
                let mockAction = MockFlowAction<Int> { currentState in
                    currentState + 5
                }
                
                flowState.dispatch(action: mockAction)
                
                then("The state should be updated to 5") {
                    XCTAssertEqual(flowState.state.value, 5)
                }
            }
        }
    }
    
    func test_multipleMockActionsUpdatesState() {
        given("A FlowState with an initial state of 0") {
            let flowState = createFlowState(initialState: 0)
            
            when("Create multiple mock actions that adds 5 to the current state and dispatch them") {
                let mockAction1 = MockFlowAction<Int> { currentState in
                    currentState + 5
                }
                
                let mockAction2 = MockFlowAction<Int> { currentState in
                    currentState + 15
                }
                
                let mockAction3 = MockFlowAction<Int> { currentState in
                    currentState - 8
                }
                
                flowState.dispatch(action: mockAction1)
                flowState.dispatch(action: mockAction2)
                flowState.dispatch(action: mockAction3)
                
                then("The state should be updated to 12") {
                    XCTAssertEqual(flowState.state.value, 12)
                }
            }
        }
    }
    
    func test_mockActionSubscriptionUpdatesState() {
        given("A FlowState with an initial state of 0") {
            let flowState = createFlowState(initialState: 0)
            
            var cancellables = Set<AnyCancellable>()

            var updatedValue = 0
            
            flowState.state.sink { newValue in
                updatedValue = newValue
            }.store(in: &cancellables)
            
            when("Create a mock action subscription that adds 5 to the current state") {
                let mockAction1 = MockFlowAction<Int> { currentState in
                    currentState + 15
                }
                
                let mockAction2 = MockFlowAction<Int> { currentState in
                    currentState - 5
                }
                
                flowState.dispatch(action: mockAction1)
                flowState.dispatch(action: mockAction2)
                
                then("The state should be updated to 10") {
                    XCTAssertEqual(updatedValue, 10)
                }
            }
        }
    }
}
