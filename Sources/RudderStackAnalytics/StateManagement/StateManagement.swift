//
//  StateManagement.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/01/25.
//

import Combine
import Foundation

// MARK: - State
/**
 A protocol that represents a reactive state container.

 The `State` protocol defines a generic interface for managing and updating state using actions. It holds a single value which can be read synchronously via `value` and observed via `publisher`. The only way to mutate it is `dispatch(action:)`, so every mutation is routed through a `StateAction` reducer.
 */
protocol State: AnyObject {

    associatedtype T: Equatable

    /**
     The current value of the state.
     */
    var value: T { get }

    /**
     A read-only publisher used to observe the state. It emits the current value immediately on subscription, followed by every subsequent *distinct* value.
     */
    var publisher: AnyPublisher<T, Never> { get }

    /**
     Returns a publisher which emits values only once a value has actually been dispatched, i.e. it skips the initial value supplied at construction time.
     */
    func observeDispatched() -> AnyPublisher<T, Never>

    /**
     Dispatches an action to update the state.
     */
    func dispatch<ActionType: StateAction>(action: ActionType) where ActionType.T == T
}

/**
 Creates a new instance of `StateImpl`.

 This function provides a convenient way to create a `StateImpl` instance with the given initial state.
 */
func createState<T: Equatable>(initialState: T) -> StateImpl<T> {
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

 `StateImpl` is a generic class that manages a reactive state container backed by Combine's `CurrentValueSubject`. The subject is kept private so that `dispatch(action:)` remains the single entry point for mutation and the reducer can never be bypassed.
 */
final class StateImpl<T: Equatable>: State {

    /**
     Pairs a value with whether it originated from a `dispatch(action:)` rather than from the initial state.

     The marker travels with the value instead of being tracked separately, so an observer can never pair the initial value with a stale marker, regardless of when it subscribes.
     */
    private struct StateValue {
        let value: T
        let isDispatched: Bool
    }

    private let subject: CurrentValueSubject<StateValue, Never>

    /**
     Serialises `dispatch(action:)` so that the read-reduce-write cycle is atomic.

     - Note: The lock is held while the new value is published. Combine delivers synchronously, so an observer must not re-enter `dispatch(action:)` on the same state from within its own subscription. Every in-tree observer hops queues via `receive(on:)`, so no observer runs inside `dispatch`.
     */
    private let dispatchLock = NSLock()

    /**
     Initializes a new instance of `StateImpl` with the given initial state.
     */
    init(initialState: T) {
        self.subject = CurrentValueSubject(StateValue(value: initialState, isDispatched: false))
    }

    var value: T {
        return self.subject.value.value
    }

    /// Deduped here, not per subscriber, matching Kotlin's `StateFlow` conflation.
    var publisher: AnyPublisher<T, Never> {
        return self.subject
            .map(\.value)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func observeDispatched() -> AnyPublisher<T, Never> {
        return self.subject
            .filter(\.isDispatched)
            .map(\.value)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /**
     Dispatches an action to update the state.
     */
    func dispatch<ActionType: StateAction>(action: ActionType) where ActionType.T == T {
        self.dispatchLock.lock()
        defer { self.dispatchLock.unlock() }

        let newState = action.reduce(currentState: self.subject.value.value)
        self.subject.send(StateValue(value: newState, isDispatched: true))
    }
}
