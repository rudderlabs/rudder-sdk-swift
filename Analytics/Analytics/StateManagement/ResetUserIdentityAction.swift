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

 - Properties:
    - `clearAnonymousId`: A boolean flag indicating whether a new anonymous ID should be generated.
 
 - Methods:
    - `reduce(currentState:)`: Resets the `UserIdentity` values of the current state.
 */
struct ResetUserIdentityAction: StateAction {
    
    typealias T = UserIdentity
    private let clearAnonymousId: Bool
    
    /**
     Initializes a `ResetUserIdentityAction` with the specified `clearAnonymousId` flag.
     
     - Parameter clearAnonymousId: Determines whether to generate a new anonymous ID.
     */
    init(clearAnonymousId: Bool) {
        self.clearAnonymousId = clearAnonymousId
    }
    
    /**
     Reduces the current user identity state by resetting its values.
     
     - Parameter currentState: The existing `UserIdentity` state.
     - Returns: A new `UserIdentity` state with reset values.
     
     - If `clearAnonymousId` is `true`, a new random anonymous ID is assigned.
     - The user ID is set to an empty string.
     - Traits value will be cleared.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.anonymousId = clearAnonymousId ? .randomUUIDString : currentState.anonymousId
        newState.userId = String.empty
        newState.traits = RudderTraits()
        return newState
    }
}
