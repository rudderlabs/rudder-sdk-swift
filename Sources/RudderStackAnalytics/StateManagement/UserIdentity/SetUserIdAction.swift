//
//  SetUserIdAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 31/01/25.
//

import Foundation

// MARK: - SetUserIdAction
/**
 An action to update the `userId` property in the `UserIdentity` state.

 The `SetUserIdAction` conforms to the `StateAction` protocol and provides the logic
 to modify the `userId` of the current state to a new value.

 - Properties:
    - `userId`: The new user ID to be set in the state.

 - Methods:
    - `reduce(currentState:)`: Updates the `userId` property of the current state with the new value.
 */
struct SetUserIdAction: StateAction {
    typealias T = UserIdentity
    private let userId: String
    
    /**
     Initializes a new `SetUserIdAction` with the provided user ID.
     
     - Parameter userId: The new user ID to be set in the state.
     */
    init(userId: String) {
        self.userId = userId
    }
    
    /**
     Updates the `userId` property of the current state to the new value.
     
     - Parameter currentState: The current `UserIdentity` state to be updated.
     - Returns: A new `UserIdentity` instance with the updated `userId`.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.userId = userId
        return newState
    }
}
