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

public protocol MessageStorage {
    func write(message: String)
    func read() -> MessageDataResult
    func remove(messageReference: String)
    func rollover()
}

public protocol Storage: KeyValueStorage, MessageStorage {
    var eventStorageMode: StorageMode { get }
}

@objc
public enum StorageMode: Int {
    case disk
    case memory
}
