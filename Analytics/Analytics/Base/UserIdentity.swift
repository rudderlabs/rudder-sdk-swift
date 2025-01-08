//
//  UserIdentity.swift
//  Analytics
//
//  Created by Satheesh Kannan on 07/01/25.
//

import Foundation

/**
 A struct representing the identity of a user, including their anonymous ID, user ID, associated traits, and external IDs.

 - Properties:
   - `anonymousId`: A unique identifier for the user when they are not logged in. Defaults to an empty string.
   - `userId`: The identifier for the logged-in user. Defaults to an empty string.
   - `traits`: A dictionary of user-specific traits. Defaults to an empty `RudderTraits` instance.
   - `externalIds`: An array of external identifiers associated with the user. Defaults to an empty array.

 - Methods:
   - `initializeState(_:)`: Creates and initializes a `UserIdentity` instance by reading stored data from a key-value storage.
 */
public struct UserIdentity {
    /// A unique identifier for the user when they are not logged in.
    var anonymousId = ""

    /// The identifier for the logged-in user.
    var userId = ""

    /// A dictionary of user-specific traits.
    var traits = RudderTraits()

    /// An array of external identifiers associated with the user.
    var externalIds = [ExternalId]()

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

        identity.anonymousId = storage.read(key: StorageKeys.anonymousId) ?? UUID().uuidString
        identity.userId = storage.read(key: StorageKeys.userId) ?? ""

        if let traitsString: String = storage.read(key: StorageKeys.traits),
           let traits = traitsString.toDictionary {
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
}
