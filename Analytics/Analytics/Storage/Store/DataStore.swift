//
//  DataStore.swift
//  Analytics
//
//  Created by Satheesh Kannan on 13/09/24.
//

import Foundation

public protocol DataStore {
    func retain(value: String)
    func retrieve() -> [Any]
    func remove(reference: String)
    func rollover()
}

final class StoreProvider {
    private init() {}
    
    static func prepareProvider(for storageMode: StorageMode, writeKey: String) -> DataStore {
        return storageMode == .disk ? DiskStore(writeKey: writeKey) : MemoryStore(writeKey: writeKey)
    }
}


