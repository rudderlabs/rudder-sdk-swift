//
//  Storage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/09/24.
//

import Foundation

@objc
public enum StorageMode: Int {
    case disk
    case memory
}

public enum StorageKey {
    case event
    case others(key: String)
}

public protocol Storage {
    var eventStorageMode: StorageMode { get }
    
    func write<T: Codable>(value: T, key: StorageKey)
    func read<T: Codable>(key: StorageKey) -> T?
    func read<T: Codable>(filePath: String) -> T?
    func remove(key: StorageKey)
    func remove(filePath: String)
    func rollover()
}

extension Storage {
    func read<T: Codable>(key: StorageKey) -> T? { return nil }
    func read<T: Codable>(filePath: String) -> T? { return nil }
}

final class BasicStorage: Storage {
    
    let writeKey: String
    let defaultsStore: DefaultsStore
    let diskStore: DiskStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.defaultsStore = DefaultsStore(writeKey: writeKey)
        self.diskStore = DiskStore(writeKey: writeKey)
    }
    
    var eventStorageMode: StorageMode {
        return .disk
    }
    
    func write<T: Codable>(value: T, key: StorageKey) {
        switch key {
        case .event:
            self.diskStore.retain(value: value, key: "Event")
        case .others(let key):
            self.defaultsStore.retain(value: value, key: key)
        }
    }
    
    func read<T: Codable>(key: StorageKey) -> T? {
        guard case .others(let key) = key else { return nil }
        return self.defaultsStore.retrieve(key: key)
    }
    
    func read<T: Codable>(filePath: String) -> T? {
        return self.diskStore.retrieve(filePath: filePath)
    }
    
    func remove(key: StorageKey) {
        guard case .others(let key) = key else { return }
        self.defaultsStore.remove(key: key)
    }
    
    func rollover() {
        self.diskStore.rollover()
    }
    
    func remove(filePath: String) {
        self.diskStore.remove(filePath: filePath)
    }
}

