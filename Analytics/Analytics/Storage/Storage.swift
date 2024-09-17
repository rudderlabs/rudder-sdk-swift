//
//  Storage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/09/24.
//

import Foundation

public protocol KeyValueStorage {
    func write<T: Codable>(value: T, key: String)
    func read<T: Codable>(key: String) -> T?
    func remove(key: String)
}

public protocol EventsStorage {
    func write<T: Codable>(value: T, key: StorageKey)
    func read<T: Codable>(filePath: String) -> T?
    func remove(filePath: String)
    func rollover()
}

public protocol Storage: KeyValueStorage, EventsStorage {
    var eventStorageMode: StorageMode { get }
}

@objc
public enum StorageMode: Int {
    case disk
    case memory
}

public enum StorageKey {
    case event
    case others(key: String)
}
