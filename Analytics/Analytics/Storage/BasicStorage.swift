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

// MARK: - KeyValueStorage
extension BasicStorage {
    func write<T: Codable>(value: T, key: String) {
        self.dataStore.retain(value: value, reference: key)
    }
    
    func read<T: Codable>(key: String) -> T? {
        return self.dataStore.retrieve(reference: key)
    }
    
    func remove(key: String) {
        self.dataStore.remove(reference: key)
    }
}
