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
protocol KeyValueStorage {
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

// MARK: - EventStorage
/**
 A protocol defining the interface for event storage operations.

 This protocol provides methods for storing, retrieving, removing, and managing event data. It is designed for asynchronous operations and supports event rollover for batching or other purposes.

 - Methods:
   - `write(event:)`: Stores a event asynchronously.
   - `read()`: Retrieves stored event asynchronously.
   - `remove(eventReference:)`: Removes a specific event using its reference and returns whether the removal was successful.
   - `rollover()`: Handles event rollover, typically used to finalize or batch events for processing.
 */
protocol EventStorage {
    /**
     Stores a event in the storage.

     - Parameter event: The event payload to store as a `String`.
     */
    func write(event: String) async

    /**
     Retrieves all stored events from the storage.

     - Returns: A `EventDataResult` containing the retrieved events.
     */
    func read() async -> EventDataResult

    /**
     Removes a specific batch from the storage.

     - Parameter batchReference: The reference of the batch to be removed.
     - Returns: A `Bool` indicating whether the batch was successfully removed.
     */
    @discardableResult
    func remove(batchReference: String) async -> Bool

    /**
     Performs a rollover operation on the storage.

     This is typically used to finalize or batch stored events for processing or uploading.
     */
    func rollover() async
}

// MARK: - Storage
/**
 A protocol that combines key-value storage and event storage functionality.

 The `Storage` protocol extends both `KeyValueStorage` and `EventStorage`, offering a unified interface for managing key-value pairs and event data. It also includes a property to specify the storage mode for events.

 - Conforms to:
   - `KeyValueStorage`: Provides methods for key-value storage operations.
   - `EventStorage`: Provides methods for event data management.

 - Properties:
   - `eventStorageMode`: Defines the mode of storage used for events.
 */
protocol Storage: KeyValueStorage, EventStorage {
    /**
     The mode of storage used for storing events.

     This property indicates the current `StorageMode` being used, which determines how events are managed within the storage system.
     */
    var eventStorageMode: StorageMode { get }
    
    /**
     Removes all batches and `UserDefaults` values associated with the current write key.

     **Note**: It is recommended to use this API during shutdown to ensure storage is not removed abruptly, which could lead to unexpected errors.
     */
    func removeAll() async
}

// MARK: - StorageMode
/**
 An enumeration representing the mode of storage used for event data.

 The `StorageMode` enum defines whether events are stored on disk or in memory.

 - Cases:
   - `disk`: Stores events on the disk, ensuring persistence across app sessions.
   - `memory`: Stores events in memory, providing faster access but no persistence.
 */
@objc(RSSStorageMode)
enum StorageMode: Int {
    /// Stores events on the disk, ensuring persistence across app sessions.
    case disk

    /// Stores events in memory, providing faster access but no persistence.
    case memory
}
