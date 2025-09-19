//
//  ResetUserIdentityAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/02/25.
//

import Foundation

// MARK: - ResetUserIdentityAction
/**
 An action that resets the `UserIdentity` state using the provided `ResetEntries`.

 This struct conforms to `StateAction` and is responsible for resetting user identity-related values.
 
 - Methods:
    - `reduce(currentState:)`: Resets the `UserIdentity` values of the current state using the specified options.
 */
struct ResetUserIdentityAction: StateAction {
    
    typealias T = UserIdentity
    
    let entries: ResetEntries
    
    /**
     Reduces the current user identity state by resetting its values by the specified options.
     
     - Parameter currentState: The existing `UserIdentity` state.
     - Returns: A new `UserIdentity` state with refreshed values.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        
        if entries.anonymousId { newState.anonymousId = .randomUUIDString }
        if entries.userId { newState.userId = String.empty }
        if entries.traits { newState.traits = Traits() }
        
        return newState
    }
}
