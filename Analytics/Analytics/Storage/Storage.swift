//
//  Storage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/09/24.
//

import Foundation

// MARK: - KeyValueStorage
/**
 A protocol that defines a simple key-value storage mechanism.

 This protocol provides methods for storing, retrieving, and removing data in a storage system using string-based keys.
 It supports encoding and decoding of data types that conform to the `Codable` protocol.

 - Methods:
   - `write<T: Codable>(value: T, key: String)`: Stores a value in the storage for a given key.
   - `read<T: Codable>(key: String) -> T?`: Retrieves a value associated with the given key.
   - `remove(key: String)`: Removes a value associated with the given key.
 */
public protocol KeyValueStorage {
    /**
     Stores a value for a given key.
     
     - Parameters:
        - value: The value to store. Must conform to the `Codable` protocol.
        - key: The key associated with the value.
     */
    func write<T: Codable>(value: T, key: String)
    
    /**
     Retrieves a value associated with the given key.

     - Parameter key: The key for which to retrieve the value.
     - Returns: The decoded value, or `nil` if no value exists for the key or if decoding fails.
     */
    func read<T: Codable>(key: String) -> T?
    
    /**
     Removes a value associated with the given key.

     - Parameter key: The key for which to remove the value.
     */
    func remove(key: String)
}

// MARK: - MessageStorage
/**
 A protocol defining the interface for message storage operations.

 This protocol provides methods for storing, retrieving, removing, and managing message data. It is designed for asynchronous operations and supports message rollover for batching or other purposes.

 - Methods:
   - `write(message:)`: Stores a message asynchronously.
   - `read()`: Retrieves stored messages asynchronously.
   - `remove(messageReference:)`: Removes a specific message using its reference and returns whether the removal was successful.
   - `rollover()`: Handles message rollover, typically used to finalize or batch messages for processing.

 */
public protocol MessageStorage {
    /**
     Stores a message in the storage.

     - Parameter message: The message to store as a `String`.
     */
    func write(message: String) async

    /**
     Retrieves all stored messages from the storage.

     - Returns: A `MessageDataResult` containing the retrieved messages.
     */
    func read() async -> MessageDataResult

    /**
     Removes a specific message from the storage.

     - Parameter messageReference: The reference of the message to be removed.
     - Returns: A `Bool` indicating whether the message was successfully removed.
     */
    @discardableResult
    func remove(messageReference: String) async -> Bool

    /**
     Performs a rollover operation on the storage.

     This is typically used to finalize or batch stored messages for processing or uploading.
     */
    func rollover() async
}

// MARK: - Storage
/**
 A protocol that combines key-value storage and message storage functionality.

 The `Storage` protocol extends both `KeyValueStorage` and `MessageStorage`, offering a unified interface for managing key-value pairs and message data. It also includes a property to specify the storage mode for events.

 - Conforms to:
   - `KeyValueStorage`: Provides methods for key-value storage operations.
   - `MessageStorage`: Provides methods for message data management.

 - Properties:
   - `eventStorageMode`: Defines the mode of storage used for events.
 */
public protocol Storage: KeyValueStorage, MessageStorage {
    /**
     The mode of storage used for storing events.

     This property indicates the current `StorageMode` being used, which determines how events are managed within the storage system.
     */
    var eventStorageMode: StorageMode { get }
}

// MARK: - StorageMode
/**
 An enumeration representing the mode of storage used for event data.

 The `StorageMode` enum defines whether events are stored on disk or in memory.

 - Cases:
   - `disk`: Stores events on the disk, ensuring persistence across app sessions.
   - `memory`: Stores events in memory, providing faster access but no persistence.
 */
public enum StorageMode: Int {
    /// Stores events on the disk, ensuring persistence across app sessions.
    case disk

    /// Stores events in memory, providing faster access but no persistence.
    case memory
}
