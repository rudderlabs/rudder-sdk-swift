//
//  SetUserIdAndTraitsAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/01/25.
//

import Foundation

// MARK: - SetUserIdAndTraitsAction
/**
 A state action responsible for setting the user ID and updating traits.

 This action modifies the `UserIdentity` state by setting the `userId` and updating the `traits`. It also handles resetting the user-related data if the `userId` changes.

 - Properties:
   - `userId`: The user identifier that will be set in the `UserIdentity` state.
   - `traits`: A dictionary containing user attributes or metadata that will be added to the user's traits.
   - `storage`: An instance of `KeyValueStorage` used for storage operations.

 - Methods:
   - `reduce(currentState:)`: This method modifies the `currentState` (`UserIdentity`) by updating the `userId` and `traits`. If the `userId` has changed, it resets the previous traits. Otherwise, it merges the new traits with the existing ones.

 */
struct SetUserIdAndTraitsAction: StateAction {
    typealias T = UserIdentity
    
    /// The user identifier to be set in the state.
    private let userId: String
    
    /// A dictionary containing the traits (attributes or metadata) associated with the user.
    private let traits: [String: Any]
    
    /// The analytics client used to interact with the analytics system.
    private let storage: KeyValueStorage
    
    /**
     Initializes the action with the specified user ID, traits and analytics client.

     - Parameters:
        - userId: The user ID to be set in the state.
        - traits: A dictionary containing the user's traits.
        - storage: The key-value storage instance to perform storage operations.
     */
    init(userId: String, traits: [String: Any], storage: KeyValueStorage) {
        self.userId = userId
        self.traits = traits
        self.storage = storage
    }
    
    /**
     Reduces the current state (`UserIdentity`) to a new state based on the specified action.
     
     If the `userId` has changed, this will reset the user's traits. Otherwise, it will merge the new traits with the existing ones.

     - Parameters:
        - currentState: The current `UserIdentity` state to be modified.
     
     - Returns: A new `UserIdentity` state with the updated `userId` and `traits`.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.userId = userId
        
        let isUserIdChanged = currentState.userId != userId
        
        if isUserIdChanged {
            currentState.resetUserIdAndTraits(self.storage)
            newState.traits = traits
        } else {
            newState.traits = currentState.traits + self.traits
        }
        
        return newState
    }
}
