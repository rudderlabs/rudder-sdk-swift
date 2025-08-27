//
//  DataStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

// MARK: - DataStore
/**
 A unified protocol designed to manage both disk and memory storage through dependency injection.
 */

protocol DataStore {
    func retain(value: String) async
    func retrieve() async -> [EventDataItem]
    func remove(reference: String) async -> Bool
    func rollover() async
    func reset() async
}

// MARK: - StoreProvider
/**
 A class responsible for supplying the DataStore object based on the specified storage mode.
 */
final class StoreProvider {
    private init() {
        /* Prevent instantiation (no-op) */
    }
    
    static func prepareProvider(for storageMode: StorageMode, writeKey: String) -> any DataStore {
        return storageMode == .disk ? DiskStore(writeKey: writeKey) : MemoryStore(writeKey: writeKey)
    }
}

// MARK: - DataStoreConstants
/**
 A struct that contains all the constants used by both the `DiskStore` and `MemoryStore`.
 */
struct DataStoreConstants {
    private init() {
        /* Prevent instantiation (no-op) */
    }
    
    static let memoryIndex = "rudderstack.event.memory.index."
    static let fileIndex = "rudderstack.event.file.index."
    static let referenceSeparator: String = "~"
    static let fileType = "tmp"
    static let fileBatchPrefix = "{\"batch\":["
    static let fileBatchSentAtSuffix = "],\"sentAt\":\""
    static let fileBatchSuffix = "\"}"
    
    private static let bytesInKilobyte: Int64 = 1024
    static var maxSize: Int64 {
        let maxSizeInKilobytes: Int64 = 32
        return bytesInKilobyte * maxSizeInKilobytes // 32 KB
    }
    
    static var maxBatchSize: Int64 {
        let maxBatchSizeInKilobytes: Int64 = 500
        return maxBatchSizeInKilobytes * bytesInKilobyte // 500 KB
    }
}
