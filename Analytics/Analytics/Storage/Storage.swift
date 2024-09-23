//
//  Storage.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/09/24.
//

import Foundation

// MARK: - KeyValueStorage
/**
 This protocol is designed to store and retrieve values using a custom UserDefaults object.
 */
public protocol KeyValueStorage {
    func write<T: Codable>(value: T, key: String)
    func read<T: Codable>(key: String) -> T?
    func remove(key: String)
}

// MARK: - MessageStorage
/**
 This protocol is designed to store and retrieve message events using either disk or memory storage.
 */
public protocol MessageStorage {
    func write(message: String)
    func read() -> MessageDataResult
    @discardableResult
    func remove(messageReference: String) -> Bool
    func rollover()
}

// MARK: - Storage
/**
 This protocol combines both the `KeyValueStorage` and `MessageStorage` protocols.
 */
public protocol Storage: KeyValueStorage, MessageStorage {
    var eventStorageMode: StorageMode { get }
}

// MARK: - StorageMode
/**
 Enum values to determine the method of storing message events.
 */
public enum StorageMode: Int {
    case disk
    case memory
}

typealias StorageAction = () -> Void

// MARK: - StorageQueue
/**
 Class which performs all storage related activities.
 */
final class StorageQueue {
    private init() {}
    private static let shared = StorageQueue()
    
    private let queue = DispatchQueue(label: "rudderstack.storage.message.queue")
    
    static func perform(_ action: @escaping StorageAction) {
        Self.shared.queue.async(execute: action)
    }
}
