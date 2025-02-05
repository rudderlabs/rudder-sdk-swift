//
//  SetUserIdTraitsAndExternalIdsAction.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/01/25.
//

import Foundation

// MARK: - SetUserIdTraitsAndExternalIdsAction
/**
 A state action responsible for setting the user ID, updating traits, and managing external identifiers.

 This action modifies the `UserIdentity` state by setting the `userId`, updating the `traits`, and merging the `externalIds`. It also handles resetting the user-related data if the `userId` changes.

 - Properties:
   - `userId`: The user identifier that will be set in the `UserIdentity` state.
   - `traits`: A dictionary containing user attributes or metadata that will be added to the user's traits.
   - `externalIds`: An array of `ExternalId` objects representing external identifiers associated with the user.
   - `storage`: An instance of `KeyValueStorage` used for storage operations.

 - Methods:
   - `reduce(currentState:)`: This method modifies the `currentState` (`UserIdentity`) by updating the `userId`, `traits`, and `externalIds`. If the `userId` has changed, it resets the previous traits and external IDs. Otherwise, it merges the new traits and external IDs with the existing ones.

 */
struct SetUserIdTraitsAndExternalIdsAction: StateAction {
    typealias T = UserIdentity
    
    /// The user identifier to be set in the state.
    private let userId: String
    
    /// A dictionary containing the traits (attributes or metadata) associated with the user.
    private let traits: [String: Any]
    
    /// A list of external identifiers linked to the user.
    private let externalIds: [ExternalId]
    
    /// The analytics client used to interact with the analytics system.
    private let storage: KeyValueStorage
    
    /**
     Initializes the action with the specified user ID, traits, external IDs, and analytics client.

     - Parameters:
        - userId: The user ID to be set in the state.
        - traits: A dictionary containing the user's traits.
        - externalIds: A list of external identifiers associated with the user.
        - storage: The key-value storage instance to perform storage operations.
     */
    init(userId: String, traits: [String : Any], externalIds: [ExternalId], storage: KeyValueStorage) {
        self.userId = userId
        self.traits = traits
        self.externalIds = externalIds
        self.storage = storage
    }
    
    /**
     Reduces the current state (`UserIdentity`) to a new state based on the specified action.
     
     If the `userId` has changed, this will reset the user's traits and external IDs. Otherwise, it will merge the new traits and external IDs with the existing ones.

     - Parameters:
        - currentState: The current `UserIdentity` state to be modified.
     
     - Returns: A new `UserIdentity` state with the updated `userId`, `traits`, and `externalIds`.
     */
    func reduce(currentState: UserIdentity) -> UserIdentity {
        var newState = currentState
        newState.userId = userId
        
        let isUserIdChanged = currentState.userId != userId
        
        if isUserIdChanged {
            currentState.resetUserIdTraitsAndExternalIds(self.storage)
        
            newState.traits = traits
            newState.externalIds = externalIds
        } else {
            newState.traits = currentState.traits + self.traits
            newState.externalIds = currentState.externalIds.mergeWithHigherPriorityTo(self.externalIds)
        }
        
        return newState
    }
}
