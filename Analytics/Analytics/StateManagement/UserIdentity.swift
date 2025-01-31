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
 
 This structure is used to manage the identification of a user, including both anonymous and logged-in states, as well as associated traits and external identifiers.

 - Properties:
   - `anonymousId`: A unique identifier for the user when they are not logged in. Defaults to an empty string.
   - `userId`: The identifier for the user when they are logged in. Defaults to an empty string.
   - `traits`: A dictionary of user-specific traits, used to store additional metadata about the user.
   - `externalIds`: An array of external identifiers associated with the user, allowing integration with external systems or platforms.

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
    
    /// An array of external identifiers associated with the user, allowing integration with external systems or platforms.
    public internal(set) var externalIds = [ExternalId]()
    
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
        
        identity.anonymousId = storage.read(key: StorageKeys.anonymousId) ?? .randomUUIDString
        identity.userId = storage.read(key: StorageKeys.userId) ?? String.empty
        
        if let traitsString: String = storage.read(key: StorageKeys.traits), let traits = traitsString.toDictionary {
            identity.traits = traits
        }
        
        if let idArray: [String] = storage.read(key: StorageKeys.externalIds) {
            identity.externalIds = idArray.compactMap {
                guard let data = $0.utf8Data else { return nil }
                return try? JSONDecoder().decode(ExternalId.self, from: data)
            }
        }
        
        return identity
    }
    
    /**
     Stores the current `anonymousId` in the specified storage.
     
     This method writes the value of `anonymousId` to the provided `KeyValueStorage` instance under the key defined in `StorageKeys.anonymousId`.
     
     - Parameter storage: The storage instance where the `anonymousId` will be saved.
     */
    func storeAnonymousId(_ storage: KeyValueStorage) {
        storage.write(value: anonymousId, key: StorageKeys.anonymousId)
    }
    
    /**
     Stores the user ID, traits, and external IDs into the specified key-value storage.

     - Parameters:
        - storage: An instance of `KeyValueStorage` where the values will be stored.
     
     The method performs the following:
     1. Writes the `userId` to the storage using the `StorageKeys.userId` key.
     2. Serializes the `traits` into a JSON string and writes it to the storage using the `StorageKeys.traits` key.
     3. Serializes each `externalId` into a JSON string (if possible), then writes the resulting array to the storage using the `StorageKeys.externalIds` key.
     */
    func storeUserIdTraitsAndExternalIds(_ storage: KeyValueStorage) {
        storage.write(value: userId, key: StorageKeys.userId)
        storage.write(value: traits.jsonString, key: StorageKeys.traits)
        
        let ids = externalIds.compactMap { $0.jsonString }
        storage.write(value: ids, key: StorageKeys.externalIds)
    }
    
    /**
     Removes the user ID, traits, and external IDs from the specified key-value storage.

     - Parameters:
        - storage: An instance of `KeyValueStorage` where the values will be removed.
     
     The method performs the following:
     1. Removes the `userId` from the storage using the `StorageKeys.userId` key.
     2. Removes the `traits` from the storage using the `StorageKeys.traits` key.
     3. Removes the `externalIds` from the storage using the `StorageKeys.externalIds` key.
     */
    func resetUserIdTraitsAndExternalIds(_ storage: KeyValueStorage) {
        storage.remove(key: StorageKeys.userId)
        storage.remove(key: StorageKeys.traits)
        storage.remove(key: StorageKeys.externalIds)
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
public struct ExternalId: Codable {
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
