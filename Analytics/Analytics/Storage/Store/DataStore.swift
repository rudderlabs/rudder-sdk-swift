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
    func retrieve() async -> [MessageDataItem]
    func remove(reference: String) async -> Bool
    func rollover() async
}

// MARK: - StoreProvider
/**
 A class responsible for supplying the DataStore object based on the specified storage mode.
 */
final class StoreProvider {
    private init() {}
    
    static func prepareProvider(for storageMode: StorageMode, writeKey: String) -> any DataStore {
        return storageMode == .disk ? DiskStore(writeKey: writeKey) : MemoryStore(writeKey: writeKey)
    }
}

// MARK: - DataStoreConstants
/**
 A struct that contains all the constants used by both the `DiskStore` and `MemoryStore`.
 */
struct DataStoreConstants {
    private init() {}
    
    static let memoryIndex = "rudderstack.message.memory.index."
    static let fileIndex = "rudderstack.message.file.index."
    static let fileNameSeparator: String = "-"
    static let fileType = "tmp"
    static let fileBatchPrefix = "{\"batch\":["
    static let fileBatchSentAtSuffix = "],\"sentAt\":\""
    static let fileBatchSuffix = "\"}"
}
