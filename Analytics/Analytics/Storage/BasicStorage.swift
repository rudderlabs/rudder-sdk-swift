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
    
    private let dataStore: DataStore
    
    init(writeKey: String, storageMode: StorageMode = Constants.defaultStorageMode) {
        self.writeKey = writeKey
        self.storageMode = storageMode
        
        self.dataStore = StoreProvider.prepareProvider(for: storageMode, writeKey: writeKey)
    }
    
    var eventStorageMode: StorageMode {
        return self.storageMode
    }
    
    func write<T: Codable>(value: T, key: StorageKey) {
        switch key {
        case .event:
            self.dataStore.retain(value: value, reference: "Event")
        case .others(let key):
            self.dataStore.retain(value: value, reference: key)
        }
    }
}

extension BasicStorage {
    func read<T: Codable>(filePath: String) -> T? {
        return self.dataStore.retrieve(reference: filePath)
    }
    
    func rollover() {
        self.dataStore.rollover()
    }
    
    func remove(filePath: String) {
        self.dataStore.remove(reference: filePath)
    }
}

extension BasicStorage {
    func read<T: Codable>(key: StorageKey) -> T? {
        guard case .others(let key) = key else { return nil }
        return self.dataStore.retrieve(reference: key)
    }
    
    func remove(key: StorageKey) {
        guard case .others(let key) = key else { return }
        self.dataStore.remove(reference: key)
    }
}
