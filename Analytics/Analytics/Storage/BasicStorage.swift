//
//  BasicStorage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/09/24.
//

import Foundation

final class BasicStorage: Storage {
    
    let writeKey: String
    let storageMode: StorageMode
    
    private let keyValueStore: KeyValueStore
    private let dataStore: DataStore
    
    init(writeKey: String, storageMode: StorageMode = Constants.defaultStorageMode) {
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
extension BasicStorage {
    
    func write(message: String) {
        self.dataStore.retain(value: message)
    }
    
    func read() -> MessageDataResult {
        let collected = self.dataStore.retrieve()
        return self.storageMode == .disk ? MessageDataResult(dataFiles: collected as? [URL]) : MessageDataResult(dataItems: collected as? [MessageDataItem])
    }
    
    func remove(messageReference: String) {
        self.dataStore.remove(reference: messageReference)
    }
    
    func rollover() {
        self.dataStore.rollover()
    }
}

// MARK: - KeyValueStorage
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
