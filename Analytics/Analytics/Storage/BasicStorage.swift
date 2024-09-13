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
    let defaultsStore: DefaultsStore
    let diskStore: DiskStore
    
    init(writeKey: String, storageMode: StorageMode = .disk) {
        self.writeKey = writeKey
        self.storageMode = storageMode
        
        self.defaultsStore = DefaultsStore(writeKey: writeKey)
        self.diskStore = DiskStore(writeKey: writeKey)
    }
    
    var eventStorageMode: StorageMode {
        return self.storageMode
    }
    
    func write<T: Codable>(value: T, key: StorageKey) {
        switch key {
        case .event:
            self.diskStore.retain(value: value)
        case .others(let key):
            self.defaultsStore.retain(value: value, key: key)
        }
    }
}

extension BasicStorage {
    func read<T: Codable>(filePath: String) -> T? {
        return self.diskStore.retrieve(filePath: filePath)
    }
    
    func rollover() {
        self.diskStore.rollover()
    }
    
    func remove(filePath: String) {
        self.diskStore.remove(filePath: filePath)
    }
}

extension BasicStorage {
    func read<T: Codable>(key: StorageKey) -> T? {
        guard case .others(let key) = key else { return nil }
        return self.defaultsStore.retrieve(key: key)
    }
    
    func remove(key: StorageKey) {
        guard case .others(let key) = key else { return }
        self.defaultsStore.remove(key: key)
    }
}
