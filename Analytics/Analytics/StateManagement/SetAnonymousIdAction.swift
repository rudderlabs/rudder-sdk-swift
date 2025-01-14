//
//  SetAnonymousIdAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/01/25.
//

import Foundation

// MARK: - SetAnonymousIdAction
/**
 An action to update the `anonymousId` property in the `UserIdentity` state.

 The `SetAnonymousIdAction` conforms to the `StateAction` protocol and provides the logic
 to modify the `anonymousId` of the current state to a new value.

 - Properties:
    - `anonymousId`: The new anonymous ID to be set in the state.

 - Methods:
    - `reduce(currentState:)`: Updates the `anonymousId` property of the current state with the new value.
 */
struct SetAnonymousIdAction: StateAction {
    typealias T = UserIdentity
    private let anonymousId: String
    
    /**
     Initializes a new `SetAnonymousIdAction` with the provided anonymous ID.
     
     - Parameter anonymousId: The new anonymous ID to be set in the state.
     */
    init(anonymousId: String) {
        self.anonymousId = anonymousId
    }
    
    /**
     Updates the `anonymousId` property of the current state to the new value.
     
     - Parameter currentState: The current `UserIdentity` state to be updated.
     - Returns: A new `UserIdentity` instance with the updated `anonymousId`.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.anonymousId = anonymousId
        return newState
    }
}
