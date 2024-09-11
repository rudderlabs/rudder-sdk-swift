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
    func read<T: Codable>(value: T, key: StorageKey) -> T?
    func remove(key: StorageKey)
    func rollover()
    func remove(filePath: String)
}

final class BasicStorage: Storage {
    
    let writeKey: String
    let defaultsStore: DefaultsStore
    
    init(writeKey: String) {
        self.writeKey = writeKey
        self.defaultsStore = DefaultsStore(writeKey: self.writeKey)
    }
    
    var eventStorageMode: StorageMode {
        return .disk
    }
    
    func write<T: Codable>(value: T, key: StorageKey) {
        switch key {
        case .event:
            break
        case .others(let key):
            self.defaultsStore.writeDefaults(value: value, key: key)
        }
    }
    
    func read<T: Codable>(value: T, key: StorageKey) -> T? {
        return switch key {
        case .event:
            nil
        case .others(key: let key):
            self.defaultsStore.readDefaults(key: key)
        }
    }
    
    func remove(key: StorageKey) {
        
    }
    
    func rollover() {
        
    }
    
    func remove(filePath: String) {
        
    }
}

