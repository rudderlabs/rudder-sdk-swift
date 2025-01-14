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

 - Properties:
   - `anonymousId`: A unique identifier for the user when they are not logged in. Defaults to an empty string.

 - Methods:
   - `initializeState(_:)`: Creates and initializes a `UserIdentity` instance by reading stored data from a key-value storage.
 */

struct UserIdentity {
    /// A unique identifier for the user when they are not logged in.
    var anonymousId = ""

    /**
     Creates and initializes a `UserIdentity` instance by reading data from the provided key-value storage.

     - Parameter storage: An instance of `KeyValueStorage` used to read the stored user identity data.
     - Returns: A fully initialized `UserIdentity` object with data from the storage or default values if not available.
     */
    static func initializeState(_ storage: KeyValueStorage) -> UserIdentity {
        var identity = UserIdentity()

        identity.anonymousId = storage.read(key: StorageKeys.anonymousId) ?? .randomUUIDString

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
}
