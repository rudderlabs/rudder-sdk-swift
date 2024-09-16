//
//  DataStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

public protocol DataStore {
    func retain<T: Codable>(value: T?, reference: String)
    func retrieve<T: Codable>(reference: String) -> T?
    func remove(reference: String)
    func rollover()
}

public extension DataStore {
    func rollover() {}
}

final class StoreProvider {
    private init() {}
    
    static func prepareProvider(for storageMode: StorageMode, writeKey: String) -> DataStore {
        return storageMode == .disk ? DiskStore(writeKey: writeKey) : MemoryStore(writeKey: writeKey)
    }
}


