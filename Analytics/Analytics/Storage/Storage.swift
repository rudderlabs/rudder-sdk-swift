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
    func write(message: String) async
    func read() async -> MessageDataResult
    @discardableResult
    func remove(messageReference: String) async -> Bool
    func rollover() async
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

// MARK: - SerializedQueue
/**
 A class that handles all storage-related activities in a synchronized manner.
 */
final class SerializedQueue {
    private init() {}
    private static let semaphore = DispatchSemaphore(value: 1)
    private static let queue = DispatchQueue(label: "rudderstack.message.storage.queue")
    
    static func perform(_ action: @escaping () -> Void) {
        self.queue.async {
            self.semaphore.wait() // Lock
            defer { self.semaphore.signal() } // Unlock when done
            action()
        }
    }
}
