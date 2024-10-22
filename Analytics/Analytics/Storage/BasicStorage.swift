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
final public class BasicStorage: Storage {
    
    let writeKey: String
    let storageMode: StorageMode
    
    private let keyValueStore: KeyValueStore
    private let dataStore: any DataStore
    
    public init(writeKey: String, storageMode: StorageMode = Constants.defaultStorageMode) {
        self.writeKey = writeKey
        self.storageMode = storageMode
        
        self.dataStore = StoreProvider.prepareProvider(for: storageMode, writeKey: writeKey)
        self.keyValueStore = KeyValueStore(writeKey: writeKey)
    }
    
    public var eventStorageMode: StorageMode {
        return self.storageMode
    }
}

// MARK: - MessageStorage
/**
 Implementation of the `MessageStorage` protocol.
 */
extension BasicStorage {
    
    public func write(message: String) {
        self.dataStore.retain(value: message)
    }
    
    public func read() -> MessageDataResult {
        let collected = self.dataStore.retrieve()
        return self.storageMode == .disk ? MessageDataResult(dataFiles: collected as? [URL]) : MessageDataResult(dataItems: collected as? [MessageDataItem])
    }
    
    public func remove(messageReference: String) -> Bool {
        return self.dataStore.remove(reference: messageReference)
    }
    
    public func rollover(_ block: VoidClosure?) {
        self.dataStore.rollover(block)
    }
}

// MARK: - KeyValueStorage
/**
 Implementation of the `KeyValueStorage` protocol.
 */
extension BasicStorage {
    public func write<T: Codable>(value: T, key: String) {
        self.keyValueStore.save(value: value, reference: key)
    }
    
    public func read<T: Codable>(key: String) -> T? {
        return self.keyValueStore.read(reference: key)
    }
    
    public func remove(key: String) {
        self.keyValueStore.delete(reference: key)
    }
}
