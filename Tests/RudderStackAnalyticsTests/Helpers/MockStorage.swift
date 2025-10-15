//
//  MockStorage.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 15/10/25.
//

import Foundation
@testable import RudderStackAnalytics

// MARK: - MockStorage
/**
 A mock implementation of the `Storage` protocol for testing purposes.
 
 This class provides an in-memory storage implementation that mimics the behavior
 of the production storage system without persisting data to disk or UserDefaults.
 Useful for unit tests where you need controlled, isolated storage behavior.
 
 Features:
 - In-memory key-value storage
 - Event batch management with rollover support
 - Thread-safe operations using actor-based concurrency
 - Configurable storage mode simulation
 - Easy test data inspection and manipulation
 */
final class MockStorage: Storage {
    
    // MARK: - Properties
    
    private let mockKeyValueStorage: MockKeyValueStorageImpl
    private let mockEventStorage: MockEventStorage
    
    let eventStorageMode: StorageMode
    
    // MARK: - Initialization
    
    /**
     Initializes MockStorage with the specified storage mode.
     
     - Parameter storageMode: The storage mode to simulate (.disk or .memory)
     */
    init(storageMode: StorageMode = .memory) {
        self.eventStorageMode = storageMode
        self.mockKeyValueStorage = MockKeyValueStorageImpl()
        self.mockEventStorage = MockEventStorage()
    }
    
    // MARK: - Storage Protocol
    
    func removeAll() async {
        await mockEventStorage.removeAll()
        mockKeyValueStorage.removeAll()
    }
}

// MARK: - KeyValueStorage Implementation

extension MockStorage {
    func write<T: Codable>(value: T, key: String) {
        mockKeyValueStorage.write(value: value, key: key)
    }
    
    func read<T: Codable>(key: String) -> T? {
        return mockKeyValueStorage.read(key: key)
    }
    
    func remove(key: String) {
        mockKeyValueStorage.remove(key: key)
    }
}

// MARK: - EventStorage Implementation

extension MockStorage {
    func write(event: String) async {
        await mockEventStorage.write(event: event)
    }
    
    func read() async -> EventDataResult {
        return await mockEventStorage.read()
    }
    
    func remove(batchReference: String) async -> Bool {
        return await mockEventStorage.remove(batchReference: batchReference)
    }
    
    func rollover() async {
        await mockEventStorage.rollover()
    }
}

// MARK: - Test Helper Methods

extension MockStorage {
    /**
     Returns all stored key-value pairs for inspection in tests.
     */
    var allKeyValuePairs: [String: Any] {
        return mockKeyValueStorage.allStoredData
    }
    
    /**
     Returns all stored events for inspection in tests.
     */
    var allEvents: [EventDataItem] {
        get async {
            return await mockEventStorage.getAllEvents()
        }
    }
    
    /**
     Clears all stored data (both key-value and events).
     */
    func clearAll() async {
        await removeAll()
    }
    
    /**
     Returns the count of stored events.
     */
    var eventCount: Int {
        get async {
            return await mockEventStorage.getEventCount()
        }
    }
}

// MARK: - MockKeyValueStorageImpl

class MockKeyValueStorageImpl: KeyValueStorage {
    
    private var storage: [String: Any] = [:]
    private let queue = DispatchQueue(label: "MockKeyValueStorage", attributes: .concurrent)
    
    func write<T: Codable>(value: T, key: String) {
        queue.async(flags: .barrier) {
            if self.isPrimitiveType(value) {
                self.storage[key] = value
            } else {
                guard let encodedData = try? JSONEncoder().encode(value) else { return }
                self.storage[key] = encodedData
            }
        }
    }
    
    func read<T: Codable>(key: String) -> T? {
        return queue.sync {
            let rawValue = self.storage[key]
            if let rawData = rawValue as? Data {
                guard let decodedValue = try? JSONDecoder().decode(T.self, from: rawData) else { return nil }
                return decodedValue
            } else {
                return rawValue as? T
            }
        }
    }
    
    func remove(key: String) {
        queue.async(flags: .barrier) {
            self.storage.removeValue(forKey: key)
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
        }
    }
    
    var allStoredData: [String: Any] {
        return queue.sync {
            return self.storage
        }
    }
    
    private func isPrimitiveType<T: Codable>(_ value: T?) -> Bool {
        guard let value = value else { return true }
        
        return switch value {
        case is Int, is Double, is Float, is NSNumber, is Bool, is String, is Character,
            is [Int], is [Double], is [Float], is [NSNumber], is [Bool], is [String], is [Character]:
            true
        default:
            false
        }
    }
}

// MARK: - MockEventStorage
/**
 Actor-based mock event storage for thread-safe operations.
 */
actor MockEventStorage {
    
    // MARK: - Properties
    
    private var currentBatch: EventDataItem = EventDataItem()
    private var closedBatches: [EventDataItem] = []
    
    // MARK: - EventStorage Protocol Methods
    
    func write(event: String) {
        if currentBatch.batch.isEmpty {
            currentBatch.batch = "{\"batch\":[\(event)"
        } else {
            currentBatch.batch += ",\(event)"
        }
    }
    
    func read() -> EventDataResult {
        var allBatches = closedBatches
        
        // Include current batch if it has events
        if !currentBatch.batch.isEmpty {
            var batchToInclude = currentBatch
            batchToInclude.batch += "]}"
            batchToInclude.isClosed = true
            allBatches.append(batchToInclude)
        }
        
        return EventDataResult(dataItems: allBatches)
    }
    
    func remove(batchReference: String) -> Bool {
        // Remove from closed batches
        if let index = closedBatches.firstIndex(where: { $0.reference == batchReference }) {
            closedBatches.remove(at: index)
            return true
        }
        
        // Check if it's the current batch
        if currentBatch.reference == batchReference {
            currentBatch = EventDataItem()
            return true
        }
        
        return false
    }
    
    func rollover() {
        guard !currentBatch.batch.isEmpty else { return }
        
        // Close current batch and move to closed batches
        currentBatch.batch += "]}"
        currentBatch.isClosed = true
        closedBatches.append(currentBatch)
        
        // Start new batch
        currentBatch = EventDataItem()
    }
    
    func removeAll() {
        currentBatch = EventDataItem()
        closedBatches.removeAll()
    }
    
    // MARK: - Test Helper Methods
    
    func getAllEvents() -> [EventDataItem] {
        var allBatches = closedBatches
        
        if !currentBatch.batch.isEmpty {
            allBatches.append(currentBatch)
        }
        
        return allBatches
    }
    
    func getEventCount() -> Int {
        var count = closedBatches.count
        if !currentBatch.batch.isEmpty {
            count += 1
        }
        return count
    }
}

// MARK: - MockStorage Factory

extension MockStorage {
    /**
     Creates a MockStorage instance configured for disk storage simulation.
     */
    static func forDiskStorage() -> MockStorage {
        return MockStorage(storageMode: .disk)
    }
    
    /**
     Creates a MockStorage instance configured for memory storage simulation.
     */
    static func forMemoryStorage() -> MockStorage {
        return MockStorage(storageMode: .memory)
    }
}
