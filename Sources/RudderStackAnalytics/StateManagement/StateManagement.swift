//
//  StateManagement.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/01/25.
//

import Combine

// MARK: - State
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
    func dispatch<ActionType: StateAction>(action: ActionType) where ActionType.T == T
}

/**
 Creates a new instance of `StateImpl`.

 This function provides a convenient way to create a `StateImpl` instance with the given initial state.
 */
func createState<T>(initialState: T) -> StateImpl<T> {
    return StateImpl(initialState: initialState)
}

// MARK: - StateAction
/**
 A protocol that represents an action that can modify the state.

 The `StateAction` protocol defines a generic interface for actions that transform the current state into a new state.
 */
protocol StateAction {
    
    associatedtype T
    /**
     Reduces the current state to a new state.
     */
    func reduce(currentState: T) -> T
}

// MARK: - StateImpl
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
    func dispatch<ActionType: StateAction>(action: ActionType) where ActionType.T == T {
        let currentState = state.value
        let newState = action.reduce(currentState: currentState)
        state.send(newState)
    }
}
