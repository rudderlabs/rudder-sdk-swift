//
//  BasicStorage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/09/24.
//

import Foundation

// MARK: - BasicStorage
/**
 The interface of the storage module, capable of handling both `KeyValueStore` and `DataStore` objects.
 */
final class BasicStorage: Storage {
    
    let writeKey: String
    let storageMode: StorageMode
    
    private let keyValueStore: KeyValueStore
    private let dataStore: any DataStore
    
    init(writeKey: String, storageMode: StorageMode = RSConstants.DefaultConfig.storageMode) {
        self.writeKey = writeKey
        self.storageMode = storageMode
        
        self.dataStore = StoreProvider.prepareProvider(for: storageMode, writeKey: writeKey)
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    var eventStorageMode: StorageMode {
        return self.storageMode
    }
}

// MARK: - MessageStorage
/**
 Implementation of the `MessageStorage` protocol.
 */
extension BasicStorage {
    
    func write(message: String) async {
        await self.dataStore.retain(value: message)
    }
    
    func read() async -> MessageDataResult {
        return await MessageDataResult(dataItems: self.dataStore.retrieve())
    }
    
    func remove(messageReference: String) async -> Bool {
        return await self.dataStore.remove(reference: messageReference)
    }
    
    func rollover() async {
        await self.dataStore.rollover()
    }
}

// MARK: - KeyValueStorage
/**
 Implementation of the `KeyValueStorage` protocol.
 */
extension BasicStorage {
    func write<T: Codable>(value: T, key: String) {
        self.keyValueStore.save(value: value, reference: key)
    }
    
    func read<T: Codable>(key: String) -> T? {
        return self.keyValueStore.read(reference: key)
    }
    
    func remove(key: String) {
        self.keyValueStore.delete(reference: key)
    }
}
