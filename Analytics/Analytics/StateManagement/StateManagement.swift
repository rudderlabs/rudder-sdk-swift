//
//  StateManagement.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/01/25.
//

import Combine

/**
 A protocol that represents a reactive state container.

 The `State` protocol defines a generic interface for managing and updating state using actions. It uses a `CurrentValueSubject` to hold the current state and notify subscribers about changes.
 */
protocol State: AnyObject {
    
    associatedtype T
    var state: CurrentValueSubject<T, Never> { get }
    /**
     Dispatches an action to update the state.
     */
    func dispatch<ActionType: Action>(action: ActionType) where ActionType.T == T
}

/**
 Creates a new instance of `FlowStateImpl`.

 This function provides a convenient way to create a `FlowStateImpl` instance with the given initial state.
 */
func createFlowState<T>(initialState: T) -> StateImpl<T> {
    return StateImpl(initialState: initialState)
}

/**
 A protocol that represents an action that can modify the state.

 The `Action` protocol defines a generic interface for actions that transform the current state into a new state.
 */
protocol Action {
    
    associatedtype T
    /**
     Reduces the current state to a new state.
     */
    func reduce(currentState: T) -> T
}

/**
 A concrete implementation of the `State` protocol.

 `StateImpl` is a generic class that manages a reactive state container using Combine's `CurrentValueSubject`. It supports dispatching actions to update the state.
 */
class StateImpl<T>: State {
    typealias T = T
    var state: CurrentValueSubject<T, Never>

    /**
     Initializes a new instance of `StateImpl` with the given initial state.
     */
    init(initialState: T) {
        self.state = CurrentValueSubject<T, Never>(initialState)
    }

    /**
     Dispatches an action to update the state.
     */
    func dispatch<ActionType: Action>(action: ActionType) where ActionType.T == T {
        let currentState = state.value
        let newState = action.reduce(currentState: currentState)
        state.send(newState)
    }
}
