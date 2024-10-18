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
public protocol DataStore {
    func retain(value: String) async
    func retrieve() -> [Any]
    func remove(reference: String) -> Bool
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


