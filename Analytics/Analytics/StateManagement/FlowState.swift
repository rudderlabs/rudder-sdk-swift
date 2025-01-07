//
//  FlowState.swift
//  Analytics
//
//  Created by Satheesh Kannan on 06/01/25.
//

import Combine

protocol FlowState: AnyObject {
    associatedtype T
    var state: CurrentValueSubject<T, Never> { get }
    
    func dispatch<Action: FlowAction>(action: Action) where Action.T == T
}

/**
 Creates a FlowState with the given initial state.
 */
func createFlowState<T>(initialState: T) -> FlowStateImpl<T> {
    return FlowStateImpl(initialState: initialState)
}


protocol FlowAction {
    associatedtype T
    
    func reduce(currentState: T) -> T
}

/**
 Implementation class for `FlowState` protocol
 */
class FlowStateImpl<T>: FlowState {
    typealias T = T
    var state: CurrentValueSubject<T, Never>
    
    init(initialState: T) {
        self.state = CurrentValueSubject<T, Never>(initialState)
    }
    
    func dispatch<Action: FlowAction>(action: Action) where Action.T == T {
        let currentState = state.value
        let newState = action.reduce(currentState: currentState)
        state.send(newState)
    }
}

