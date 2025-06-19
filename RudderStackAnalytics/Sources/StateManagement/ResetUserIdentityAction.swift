//
//  ResetUserIdentityAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/02/25.
//

import Foundation

// MARK: - ResetUserIdentityAction
/**
 An action that resets the `UserIdentity` state.

 This struct conforms to `StateAction` and is responsible for resetting user identity-related values.
 
 - Methods:
    - `reduce(currentState:)`: Resets the `UserIdentity` values of the current state.
 */
struct ResetUserIdentityAction: StateAction {
    
    typealias T = UserIdentity
    
    /**
     Reduces the current user identity state by resetting its values.
     
     - Parameter currentState: The existing `UserIdentity` state.
     - Returns: A new `UserIdentity` state with reset values.
     
     - A new anonymous ID is generated.
     - The user ID is set to an empty string.
     - Traits value will be cleared.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.anonymousId = .randomUUIDString
        newState.userId = String.empty
        newState.traits = RudderTraits()
        return newState
    }
}
