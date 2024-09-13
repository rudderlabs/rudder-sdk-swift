//
//  Storage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/09/24.
//

import Foundation

public protocol DefaultsStorage {
    func write<T: Codable>(value: T, key: StorageKey)
    func read<T: Codable>(key: StorageKey) -> T?
    func remove(key: StorageKey)
}

public protocol DiskStorage {
    func write<T: Codable>(value: T, key: StorageKey)
    func read<T: Codable>(filePath: String) -> T?
    func remove(filePath: String)
    func rollover()
}

public protocol Storage: DefaultsStorage, DiskStorage {
    var eventStorageMode: StorageMode { get }
}

extension Storage {
    func read<T: Codable>(key: StorageKey) -> T? { return nil }
    func read<T: Codable>(filePath: String) -> T? { return nil }
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
