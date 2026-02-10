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
    
    private let mockKeyValueStorage: MockKeyValueStorage
    private let mockEventStorage: MockEventStorage
    
    let eventStorageMode: StorageMode
    
    // MARK: - Initialization
    
    /**
     Initializes MockStorage with the specified storage mode.
     
     - Parameter storageMode: The storage mode to simulate (.disk or .memory)
     */
    init(storageMode: StorageMode = .memory) {
        self.eventStorageMode = storageMode
        self.mockKeyValueStorage = MockKeyValueStorage()
        self.mockEventStorage = MockEventStorage()
    }
    
    // MARK: - Storage Protocol
    
    func removeAll() async {
        mockEventStorage.removeAll()
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
        mockEventStorage.write(event: event)
    }
    
    func read() async -> EventDataResult {
        return mockEventStorage.read()
    }
    
    func remove(batchReference: String) async -> Bool {
        return mockEventStorage.remove(batchReference: batchReference)
    }
    
    func rollover() async {
        mockEventStorage.rollover()
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
        return mockEventStorage.getAllEvents()
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
    var batchCount: Int {
        return mockEventStorage.getBatchCount()
    }
    
    /**
     Returns the number of events in the current batch (before rollover).
     This is useful for checking event count without triggering rollover.
     */
    var currentBatchEventCount: Int {
        return mockEventStorage.currentBatchEventCount
    }

    /**
     Returns the total number of individual events across all batches (current + closed).
     This provides a count of all events regardless of batch boundaries.
     */
    var totalEventCount: Int {
        return mockEventStorage.totalEventCount
    }
}

extension MockStorage {

    /** Polling interval in nanoseconds for wait methods. */
    static var pollInterval: UInt64 { 10_000_000 } // 10ms
    
    /**
     Waits for events to be stored with optional predicate filtering.
     
     - Parameters:
     - expectedCount: Minimum number of events expected
     - timeout: Maximum time to wait in seconds
     - predicate: Optional predicate to filter events
     - Returns: True if condition was met within timeout, false otherwise
     */
    @discardableResult
    func waitForEvents(
        expectedCount: Int = 1,
        timeout: TimeInterval = 2.0,
        predicate: ((String) -> Bool)? = nil
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            // First check if we have enough events in current batch without rollover
            if predicate == nil && currentBatchEventCount >= expectedCount {
                return true
            }
            
            await rollover()
            let result = await read()
            
            let relevantItems = result.dataItems.filter { item in
                if let predicate = predicate {
                    return predicate(item.batch)
                }
                return true
            }
            
            if relevantItems.count >= expectedCount {
                return true
            }
            
            try? await Task.sleep(nanoseconds: Self.pollInterval)
        }
        return false
    }
    
    /**
     Waits for events containing specific content.
     
     - Parameters:
     - content: Text content to search for in event batches
     - expectedCount: Minimum number of matching events expected
     - timeout: Maximum time to wait in seconds
     - Returns: True if condition was met within timeout, false otherwise
     */
    @discardableResult
    func waitForEventsContaining(
        _ content: String,
        expectedCount: Int = 1,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        return await waitForEvents(
            expectedCount: expectedCount,
            timeout: timeout,
            predicate: { batch in
                batch.contains(content)
            }
        )
    }
    
    /**
     Waits for a specific number of events in the current batch without rollover.
     This is useful for testing scenarios where you want to check event accumulation
     before batch processing occurs.
     
     - Parameters:
     - expectedCount: Expected number of events in current batch
     - timeout: Maximum time to wait in seconds
     - Returns: True if condition was met within timeout, false otherwise
     */
    @discardableResult
    func waitForCurrentBatchEvents(
        expectedCount: Int = 1,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            if currentBatchEventCount >= expectedCount {
                return true
            }
            await Task.yield()
        }
        return false
    }
    
    /**
     Waits for a specific key to exist in storage.
     
     - Parameters:
       - key: The key to wait for
       - timeout: Maximum time to wait in seconds
     - Returns: True if key exists within timeout, false otherwise
     */
    @discardableResult
    func waitForKeyValue(
        key: String,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            // Check if key exists in storage directly
            if mockKeyValueStorage.allStoredData[key] != nil {
                return true
            }
            try? await Task.sleep(nanoseconds: Self.pollInterval)
        }
        return false
    }
    
    /**
     Waits for a specific key-value pair with expected value.
     
     - Parameters:
       - key: The key to wait for
       - expectedValue: The expected value for the key
       - timeout: Maximum time to wait in seconds
     - Returns: True if key-value pair matches within timeout, false otherwise
     */
    @discardableResult
    func waitForKeyValue<T: Codable & Equatable>(
        key: String,
        expectedValue: T,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            let value: T? = mockKeyValueStorage.read(key: key)
            if let value = value, value == expectedValue {
                return true
            }
            try? await Task.sleep(nanoseconds: Self.pollInterval)
        }
        return false
    }
    
    /**
     Waits for a key-value pair with a predicate condition.
     
     - Parameters:
        - key: The key to wait for
        - timeout: Maximum time to wait in seconds
        - predicate: Predicate to evaluate the stored value
     - Returns: True if predicate condition is met within timeout, false otherwise
     */
    @discardableResult
    func waitForKeyValue<T: Codable>(
        key: String,
        timeout: TimeInterval = 2.0,
        predicate: @escaping (T) -> Bool
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            let value: T? = mockKeyValueStorage.read(key: key)
            if let value = value, predicate(value) {
                return true
            }
            await Task.yield()
        }
        return false
    }
    
    /**
     Waits until a given key is removed (i.e., no longer present) from the storage.
     
     - Parameters:
       - key: The key to monitor for removal.
       - timeout: The maximum duration to wait, in seconds. Default is `2.0`.
     - Returns: `true` if the key was removed within the timeout period, otherwise `false`.
     */
    @discardableResult
    func waitForKeyRemoval(
        key: String,
        timeout: TimeInterval = 2.0
    ) async -> Bool {
        let start = Date()
        
        while Date().timeIntervalSince(start) < timeout {
            // Check if key no longer exists in storage
            if mockKeyValueStorage.allStoredData[key] == nil {
                return true
            }
            try? await Task.sleep(nanoseconds: Self.pollInterval)
        }
        return false
    }
}

// MARK: - MockKeyValueStorage

class MockKeyValueStorage: KeyValueStorage {

    private var storage: [String: Any] = [:]

    func write<T: Codable>(value: T, key: String) {
        if isPrimitiveType(value) {
            storage[key] = value
        } else {
            guard let encodedData = try? JSONEncoder().encode(value) else { return }
            storage[key] = encodedData
        }
    }

    func read<T: Codable>(key: String) -> T? {
        let rawValue = storage[key]
        if let rawData = rawValue as? Data {
            guard let decodedValue = try? JSONDecoder().decode(T.self, from: rawData) else { return nil }
            return decodedValue
        } else {
            return rawValue as? T
        }
    }

    func remove(key: String) {
        storage.removeValue(forKey: key)
    }

    func removeAll() {
        storage.removeAll()
    }

    var allStoredData: [String: Any] {
        return storage
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
 Class-based mock event storage for thread-safe test operations.
 */
final class MockEventStorage {

    // MARK: - Properties

    private var currentBatch: EventDataItem = EventDataItem()
    private var closedBatches: [EventDataItem] = []
    private var _currentBatchEventCount: Int = 0
    private var _totalEventCount: Int = 0
    private let queue = DispatchQueue(label: "MockEventStorage.queue")

    var currentBatchEventCount: Int {
        queue.sync { _currentBatchEventCount }
    }

    var totalEventCount: Int {
        queue.sync { _totalEventCount }
    }

    // MARK: - EventStorage Protocol Methods

    func write(event: String) {
        queue.sync {
            // Auto-split: if current batch exceeds max size, close it and start a new one
            if let existingData = self.currentBatch.batch.utf8Data,
               existingData.count > DataStoreConstants.maxBatchSize {
                self.currentBatch.batch += DataStoreConstants.fileBatchSentAtSuffix + String.currentTimeStamp + DataStoreConstants.fileBatchSuffix
                self.currentBatch.isClosed = true
                self.closedBatches.append(self.currentBatch)
                self.currentBatch = EventDataItem()
                self._currentBatchEventCount = 0
            }

            if self.currentBatch.batch.isEmpty {
                self.currentBatch.batch = "{\"batch\":[\(event)"
            } else {
                self.currentBatch.batch += ",\(event)"
            }
            self._currentBatchEventCount += 1
            self._totalEventCount += 1
        }
    }

    func read() -> EventDataResult {
        queue.sync {
            // Only return closed batches, matching production MemoryStore.retrieve() behavior
            return EventDataResult(dataItems: self.closedBatches)
        }
    }

    func remove(batchReference: String) -> Bool {
        queue.sync {
            // Remove from closed batches
            if let index = self.closedBatches.firstIndex(where: { $0.reference == batchReference }) {
                self.closedBatches.remove(at: index)
                return true
            }

            // Check if it's the current batch
            if self.currentBatch.reference == batchReference {
                self.currentBatch = EventDataItem()
                self._currentBatchEventCount = 0
                return true
            }

            return false
        }
    }

    func rollover() {
        queue.sync {
            guard !self.currentBatch.batch.isEmpty else { return }

            // Close current batch and move to closed batches
            self.currentBatch.batch += DataStoreConstants.fileBatchSentAtSuffix + String.currentTimeStamp + DataStoreConstants.fileBatchSuffix
            self.currentBatch.isClosed = true
            self.closedBatches.append(self.currentBatch)

            // Start new batch and reset counter
            self.currentBatch = EventDataItem()
            self._currentBatchEventCount = 0
        }
    }

    func removeAll() {
        queue.sync {
            self.currentBatch = EventDataItem()
            self.closedBatches.removeAll()
            self._currentBatchEventCount = 0
            self._totalEventCount = 0
        }
    }

    // MARK: - Test Helper Methods

    func getAllEvents() -> [EventDataItem] {
        queue.sync {
            var allBatches = self.closedBatches
            if !self.currentBatch.batch.isEmpty {
                allBatches.append(self.currentBatch)
            }
            return allBatches
        }
    }

    func getBatchCount() -> Int {
        queue.sync {
            var count = self.closedBatches.count
            if !self.currentBatch.batch.isEmpty {
                count += 1
            }
            return count
        }
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
