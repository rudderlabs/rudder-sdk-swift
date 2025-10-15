//
//  StorageModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Testing
@testable import RudderStackAnalytics

// MARK: - StorageModuleTests
@Suite("Storage Module Tests")
struct StorageModuleTests {
    
    // MARK: - Test Data
    let sampleEvent = "{\"event\":\"test_event\",\"properties\":{\"key\":\"value\"}}"
    
    // MARK: - Key-Value Storage Tests
    
    @Test("Given MockStorage when writing primitive types then values are stored and retrievable")
    func writePrimitiveTypes() {
        let storage = MockStorage.forMemoryStorage()
        
        // Test Int
        let intValue = 42
        storage.write(value: intValue, key: "IntValue")
        let storedInt: Int? = storage.read(key: "IntValue")
        #expect(storedInt != nil)
        #expect(storedInt == intValue)
        
        // Test Double
        let doubleValue = 3.14
        storage.write(value: doubleValue, key: "DoubleValue")
        let storedDouble: Double? = storage.read(key: "DoubleValue")
        #expect(storedDouble != nil)
        #expect(storedDouble == doubleValue)
        
        // Test String
        let stringValue = "test_string"
        storage.write(value: stringValue, key: "StringValue")
        let storedString: String? = storage.read(key: "StringValue")
        #expect(storedString != nil)
        #expect(storedString == stringValue)
        
        // Test Bool
        let boolValue = true
        storage.write(value: boolValue, key: "BoolValue")
        let storedBool: Bool? = storage.read(key: "BoolValue")
        #expect(storedBool != nil)
        #expect(storedBool == boolValue)
    }
    
    @Test("Given MockStorage when writing complex Codable objects then objects are properly encoded and decoded")
    func writeComplexObjects() {
        struct TestObject: Codable, Equatable {
            let name: String
            let age: Int
            let isActive: Bool
        }
        
        let storage = MockStorage.forMemoryStorage()
        let testObject = TestObject(name: "John Doe", age: 30, isActive: true)
        
        storage.write(value: testObject, key: "ComplexObject")
        let storedObject: TestObject? = storage.read(key: "ComplexObject")
        
        #expect(storedObject != nil)
        #expect(storedObject == testObject)
    }
    
    @Test("Given stored values when removing by key then values are no longer retrievable")
    func removeValues() {
        let storage = MockStorage.forMemoryStorage()
        
        // Store values
        storage.write(value: 123, key: "IntValue")
        storage.write(value: "test", key: "StringValue")
        
        // Verify they exist
        let storedInt: Int? = storage.read(key: "IntValue")
        let storedString: String? = storage.read(key: "StringValue")
        #expect(storedInt == 123)
        #expect(storedString == "test")
        
        // Remove values
        storage.remove(key: "IntValue")
        storage.remove(key: "StringValue")
        
        // Verify they're removed
        let removedInt: Int? = storage.read(key: "IntValue")
        let removedString: String? = storage.read(key: "StringValue")
        #expect(removedInt == nil)
        #expect(removedString == nil)
    }
    
    @Test("Given stored key-value pairs when accessing helper methods then all data is visible for inspection")
    func testHelperMethods() {
        let storage = MockStorage.forMemoryStorage()
        
        storage.write(value: "value1", key: "key1")
        storage.write(value: 42, key: "key2")
        storage.write(value: true, key: "key3")
        
        let allPairs = storage.allKeyValuePairs
        #expect(allPairs.count == 3)
        #expect(allPairs["key1"] as? String == "value1")
        #expect(allPairs["key2"] as? Int == 42)
        #expect(allPairs["key3"] as? Bool == true)
    }
    
    // MARK: - Event Storage Tests
    
    @Test("Given memory storage when writing events then events are batched and readable")
    func writeAndReadEventsMemory() async {
        let storage = MockStorage.forMemoryStorage()
        #expect(storage.eventStorageMode == .memory)
        
        await storage.write(event: sampleEvent)
        let result = await storage.read()
        
        #expect(result.dataItems.count == 1)
        let batch = result.dataItems.first!
        #expect(batch.batch.contains(sampleEvent))
        #expect(batch.isClosed == true)
    }
    
    @Test("Given disk storage when writing events then events are batched and readable")
    func writeAndReadEventsDisk() async {
        let storage = MockStorage.forDiskStorage()
        #expect(storage.eventStorageMode == .disk)
        
        await storage.write(event: sampleEvent)
        let result = await storage.read()
        
        #expect(result.dataItems.count == 1)
        let batch = result.dataItems.first!
        #expect(batch.batch.contains(sampleEvent))
        #expect(batch.isClosed == true)
    }
    
    @Test("Given storage when writing multiple events then all events are included in single batch")
    func writeMultipleEvents() async {
        let storage = MockStorage.forMemoryStorage()
        
        let event1 = "{\"event\":\"event1\"}"
        let event2 = "{\"event\":\"event2\"}"
        let event3 = "{\"event\":\"event3\"}"
        
        await storage.write(event: event1)
        await storage.write(event: event2)
        await storage.write(event: event3)
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batch = result.dataItems.first!
        #expect(batch.batch.contains(event1))
        #expect(batch.batch.contains(event2))
        #expect(batch.batch.contains(event3))
    }
    
    @Test("Given events and rollover operations when batches are closed then events are separated into distinct batches")
    func rolloverFunctionality() async {
        let storage = MockStorage.forMemoryStorage()
        
        let event1 = "{\"event\":\"event1\"}"
        let event2 = "{\"event\":\"event2\"}"
        
        // Write first event and rollover
        await storage.write(event: event1)
        await storage.rollover()
        
        // Write second event and rollover
        await storage.write(event: event2)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 2)
        
        // Both batches should be closed
        #expect(result.dataItems[0].isClosed == true)
        #expect(result.dataItems[1].isClosed == true)
        
        // Each batch should contain its respective event
        #expect(result.dataItems[0].batch.contains(event1))
        #expect(result.dataItems[1].batch.contains(event2))
    }
    
    @Test("Given stored batch when removing by reference then specific batch is deleted and others remain")
    func removeBatchByReference() async {
        let storage = MockStorage.forMemoryStorage()
        
        await storage.write(event: sampleEvent)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchReference = result.dataItems.first!.reference
        let wasRemoved = await storage.remove(batchReference: batchReference)
        
        #expect(wasRemoved == true)
        
        let resultAfterRemoval = await storage.read()
        #expect(resultAfterRemoval.dataItems.count == 0)
    }
    
    @Test("Given multiple stored batches when calling removeAll then all event data is cleared")
    func removeAllEvents() async {
        let storage = MockStorage.forMemoryStorage()
        
        // Write multiple events across different batches
        await storage.write(event: "{\"event\":\"event1\"}")
        await storage.rollover()
        await storage.write(event: "{\"event\":\"event2\"}")
        await storage.rollover()
        await storage.write(event: "{\"event\":\"event3\"}")
        await storage.rollover()
        
        let resultBeforeRemoval = await storage.read()
        #expect(resultBeforeRemoval.dataItems.count == 3)
        
        // Remove all events
        await storage.removeAll()
        
        let resultAfterRemoval = await storage.read()
        #expect(resultAfterRemoval.dataItems.count == 0)
    }
    
    @Test("Given events in various batches when checking event count then accurate count is returned")
    func eventCountHelper() async {
        let storage = MockStorage.forMemoryStorage()
        
        // Initially no events
        let initialCount = await storage.eventCount
        #expect(initialCount == 0)
        
        // Add some events
        await storage.write(event: "{\"event\":\"event1\"}")
        let countAfterFirstEvent = await storage.eventCount
        #expect(countAfterFirstEvent == 1)
        
        await storage.write(event: "{\"event\":\"event2\"}")
        let countAfterSecondEvent = await storage.eventCount
        #expect(countAfterSecondEvent == 1) // Still in same batch
        
        await storage.rollover()
        await storage.write(event: "{\"event\":\"event3\"}")
        let countAfterRollover = await storage.eventCount
        #expect(countAfterRollover == 2) // Now in separate batches
    }
    
    @Test("Given events in open and closed batches when accessing all events then complete event list is returned")
    func getAllEventsHelper() async {
        let storage = MockStorage.forMemoryStorage()
        
        await storage.write(event: "{\"event\":\"event1\"}")
        await storage.rollover()
        await storage.write(event: "{\"event\":\"event2\"}")
        
        let allEvents = await storage.allEvents
        #expect(allEvents.count == 2)
        
        // First should be closed, second should be open
        #expect(allEvents[0].isClosed == true)
        #expect(allEvents[1].isClosed == false)
    }
    
    @Test("Given storage with both key-value and event data when clearing all then complete storage is reset")
    func clearAllFunctionality() async {
        let storage = MockStorage.forMemoryStorage()
        
        // Add both key-value and event data
        storage.write(value: "test_value", key: "test_key")
        await storage.write(event: sampleEvent)
        await storage.rollover()
        
        // Verify data exists
        let storedValue: String? = storage.read(key: "test_key")
        let events = await storage.read()
        #expect(storedValue == "test_value")
        #expect(events.dataItems.count == 1)
        
        // Clear all
        await storage.clearAll()
        
        // Verify everything is cleared
        let clearedValue: String? = storage.read(key: "test_key")
        let clearedEvents = await storage.read()
        #expect(clearedValue == nil)
        #expect(clearedEvents.dataItems.count == 0)
    }
    
    // MARK: - Storage Mode Tests
    
    @Test("Given storage mode configuration when creating MockStorage then correct mode is set", arguments: [StorageMode.disk, StorageMode.memory])
    func storageMode(_ mode: StorageMode) {
        let storage = MockStorage(storageMode: mode)
        #expect(storage.eventStorageMode == mode)
    }
    
    @Test("Given factory methods when creating storage instances then appropriate storage modes are configured")
    func factoryMethods() {
        let diskStorage = MockStorage.forDiskStorage()
        let memoryStorage = MockStorage.forMemoryStorage()
        
        #expect(diskStorage.eventStorageMode == .disk)
        #expect(memoryStorage.eventStorageMode == .memory)
    }
}
