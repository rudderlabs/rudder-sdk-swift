//
//  UserIdentity.swift
//  Analytics
//
//  Created by Satheesh Kannan on 07/01/25.
//

import Foundation

// MARK: - UserIdentity
/**
 A struct representing the identity of a user.
 
 This structure is used to manage the identification of a user, including both anonymous and logged-in states, as well as associated traits.

 - Properties:
   - `anonymousId`: A unique identifier for the user when they are not logged in. Defaults to an empty string.
   - `userId`: The identifier for the user when they are logged in. Defaults to an empty string.
   - `traits`: A dictionary of user-specific traits, used to store additional metadata about the user.

 - Methods:
   - `initializeState(_:)`: Creates and initializes a `UserIdentity` instance by reading stored data from a key-value storage.
 */
public struct UserIdentity {
    /// A unique identifier for the user when they are not logged in. Defaults to an empty string.
    public internal(set) var anonymousId = String.empty
    
    /// The identifier for the user when they are logged in. Defaults to an empty string.
    public internal(set) var userId = String.empty
    
    /// A dictionary of user-specific traits, used to store additional metadata about the user.
    public internal(set) var traits = RudderTraits()
    
    /**
     Creates and initializes a `UserIdentity` instance by reading data from the provided key-value storage.
     
     - Parameter storage: An instance of `KeyValueStorage` used to read the stored user identity data.
     - Returns: A fully initialized `UserIdentity` object with data from the storage or default values if not available.
     
     The method performs the following steps:
     1. Reads the `anonymousId` from storage or generates a new UUID.
     2. Reads the `userId` from storage or sets it to an empty string.
     3. Parses and assigns user traits from the stored JSON string, if available.
     4. Decodes and assigns external IDs from the stored array of JSON strings.
     */
    
    static func initializeState(_ storage: KeyValueStorage) -> UserIdentity {
        var identity = UserIdentity()
        
        identity.anonymousId = storage.read(key: Constants.StorageKeys.anonymousId) ?? .randomUUIDString
        identity.userId = storage.read(key: Constants.StorageKeys.userId) ?? String.empty
        
        if let traitsString: String = storage.read(key: Constants.StorageKeys.traits), let traits = traitsString.toDictionary {
            identity.traits = traits
        }
        
        return identity
    }
    
}

// MARK: - Helpers

extension UserIdentity {
    /**
     Stores the current `anonymousId` in the specified storage.
     
     This method writes the value of `anonymousId` to the provided `KeyValueStorage` instance under the key defined in `Constants.StorageKeys.anonymousId`.
     
     - Parameter storage: The storage instance where the `anonymousId` will be saved.
     */
    func storeAnonymousId(_ storage: KeyValueStorage) {
        storage.write(value: anonymousId, key: Constants.StorageKeys.anonymousId)
    }
    
    /**
     Stores the current `userId` in the specified storage.
     
     This method writes the value of `userId` to the provided `KeyValueStorage` instance under the key defined in `Constants.StorageKeys.userId`.
     
     - Parameter storage: The storage instance where the `userId` will be saved.
     */
    func storeUserId(_ storage: KeyValueStorage) {
        storage.write(value: userId, key: Constants.StorageKeys.userId)
    }
    
    /**
     Stores the user ID, and traits into the specified key-value storage.

     - Parameters:
        - storage: An instance of `KeyValueStorage` where the values will be stored.
     
     The method performs the following:
     1. Writes the `userId` to the storage using the `Constants.StorageKeys.userId` key.
     2. Serializes the `traits` into a JSON string and writes it to the storage using the `Constants.StorageKeys.traits` key.
     */
    func storeUserIdAndTraits(_ storage: KeyValueStorage) {
        self.storeUserId(storage)
        storage.write(value: traits.jsonString, key: Constants.StorageKeys.traits)
    }
    
    /**
     Removes the user ID and traits from the specified key-value storage.

     - Parameters:
        - storage: An instance of `KeyValueStorage` where the values will be removed.
     
     The method performs the following:
     1. Removes the `userId` from the storage using the `Constants.StorageKeys.userId` key.
     2. Removes the `traits` from the storage using the `Constants.StorageKeys.traits` key.
     */
    func resetUserIdAndTraits(_ storage: KeyValueStorage) {
        storage.remove(key: Constants.StorageKeys.userId)
        storage.remove(key: Constants.StorageKeys.traits)
    }
    
    /**
     Resets the user identity by clearing stored identifiers and traits.

     - Parameters:
       - clearAnonymousId: A boolean flag indicating whether the anonymous ID should be stored before resetting.
       - storage: The storage instance used to remove user-related data.

     If `clearAnonymousId` is `true`, the function stores the current anonymous ID before resetting other user identity-related data, such as user ID and traits.
    */
    func resetUserIdentity(clearAnonymousId: Bool, storage: Storage) {
        if clearAnonymousId {
            self.storeAnonymousId(storage)
        }
        
        self.resetUserIdAndTraits(storage)
    }
    
    /**
     Resolves the preferred previous identifier for the user.

     This function determines the appropriate identifier to use based on the following priority:
     1. If the provided `previousId` is not empty, it is returned.
     2. If the instance's `userId` is not empty, it is returned.
     3. If both are empty, the instance's `anonymousId` is returned.

     - Parameter previousId: The provided previous identifier to evaluate.
     - Returns: A `String` representing the resolved identifier.
     */
    func resolvePreferredPreviousId(_ previousId: String) -> String {
        if !previousId.isEmpty {
            return previousId
        } else if !self.userId.isEmpty {
            return self.userId
        }
        return self.anonymousId
    }
}

/**
 A struct representing an external identifier associated with the user.
 
 - Properties:
 - `type`: The type of the external identifier
 - `id`: The value of the external identifier.
 
 - Conformance:
 - `Codable`: Allows the `ExternalId` to be encoded and decoded using `JSONEncoder` and `JSONDecoder`.
 */
public struct ExternalId: Codable, Equatable {
    /// The type of the external identifier.
    var type: String
    
    /// The value of the external identifier.
    var id: String
    
    /**
     Initializes a new instance of `ExternalId` with the given `type` and `id`.
     
     - Parameters:
        - type: The type of the external identifier (e.g., "google", "facebook").
        - id: The value of the external identifier (e.g., "user_12345").
     
     - Returns: A new `ExternalId` instance.
     */
    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }
}
