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
    
    // MARK: - Key-Value Storage Tests
    @Test("given memory storage, when writing primitive types, then values are stored correctly")
    func writePrimitiveTypes() {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        
        // Test Int
        let intValue = 1
        storage.write(value: intValue, key: "IntValue")
        let storedInt: Int? = storage.read(key: "IntValue")
        #expect(storedInt != nil)
        
        // Test Double
        let doubleValue = 2.0
        storage.write(value: doubleValue, key: "DoubleValue")
        let storedDouble: Double? = storage.read(key: "DoubleValue")
        #expect(storedDouble != nil)
        
        // Test String
        let stringValue = "3"
        storage.write(value: stringValue, key: "StringValue")
        let storedString: String? = storage.read(key: "StringValue")
        #expect(storedString != nil)
        
        // Test Bool
        let boolValue = true
        storage.write(value: boolValue, key: "BoolValue")
        let storedBool: Bool? = storage.read(key: "BoolValue")
        #expect(storedBool != nil)
    }
    
    @Test("given stored primitive values, when reading them, then exact values are retrieved")
    func readPrimitiveTypes() {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        
        // Test Int
        let intValue = 1
        storage.write(value: intValue, key: "IntValue")
        let storedInt: Int? = storage.read(key: "IntValue")
        #expect(intValue == storedInt)
        
        // Test Double
        let doubleValue = 2.0
        storage.write(value: doubleValue, key: "DoubleValue")
        let storedDouble: Double? = storage.read(key: "DoubleValue")
        #expect(doubleValue == storedDouble)
        
        // Test String
        let stringValue = "3"
        storage.write(value: stringValue, key: "StringValue")
        let storedString: String? = storage.read(key: "StringValue")
        #expect(stringValue == storedString)
        
        // Test Bool
        let boolValue = true
        storage.write(value: boolValue, key: "BoolValue")
        let storedBool: Bool? = storage.read(key: "BoolValue")
        #expect(boolValue == storedBool)
    }
    
    @Test("given stored values, when removing them by key, then values are no longer retrievable")
    func deleteValues() {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        
        // Test Int removal
        let intValue = 1
        storage.write(value: intValue, key: "IntValue")
        storage.remove(key: "IntValue")
        let storedInt: Int? = storage.read(key: "IntValue")
        #expect(storedInt == nil)
        
        // Test Double removal
        let doubleValue = 2.0
        storage.write(value: doubleValue, key: "DoubleValue")
        storage.remove(key: "DoubleValue")
        let storedDouble: Double? = storage.read(key: "DoubleValue")
        #expect(storedDouble == nil)
        
        // Test String removal
        let stringValue = "3"
        storage.write(value: stringValue, key: "StringValue")
        storage.remove(key: "StringValue")
        let storedString: String? = storage.read(key: "StringValue")
        #expect(storedString == nil)
        
        // Test Bool removal
        let boolValue = true
        storage.write(value: boolValue, key: "BoolValue")
        storage.remove(key: "BoolValue")
        let storedBool: Bool? = storage.read(key: "BoolValue")
        #expect(storedBool == nil)
    }
    
    // MARK: - Disk Storage Tests
    @Test("given disk storage, when writing an event, then event is stored and readable after rollover")
    func writeEventToDisk() async {
        let storage = MockProvider.clientWithDiskStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        let result = await storage.read().dataItems
        #expect(!result.isEmpty)
    }
    
    @Test("given disk storage with written events, when reading them, then events are accessible")
    func readEventFromDisk() async {
        let storage = MockProvider.clientWithDiskStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let files = await storage.read().dataItems
        #expect(!files.isEmpty)
    }
    
    @Test("given disk storage with stored events, when removing by batch reference, then specific event is deleted")
    func removeEventFromDisk() async {
        let storage = MockProvider.clientWithDiskStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        let result = await storage.read().dataItems
        
        guard let item = result.first else {
            Issue.record("No events found after writing")
            return
        }
        
        let isRemoved = await storage.remove(batchReference: item.reference)
        #expect(isRemoved == true)
    }
    
    @Test("given disk storage with multiple events, when calling removeAll, then all events are cleared")
    func removeAllEventsFromDisk() async {
        let storage = MockProvider.clientWithDiskStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        // Write multiple events
        await storage.write(event: eventJson)
        await storage.rollover()
        await storage.write(event: eventJson)
        await storage.rollover()
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        #expect(!resultItems.isEmpty)
        
        // Remove all events using removeAll method
        await storage.removeAll()
        
        let dataItemsAfterRemoval = await storage.read().dataItems
        #expect(dataItemsAfterRemoval.isEmpty)
    }
    
    @Test("given disk storage, when performing rollover operation, then events are properly batched")
    func rolloverEventOnDisk() async {
        let storage = MockProvider.clientWithDiskStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        // Clear all existing files
        await storage.rollover()
        let files = await storage.read().dataItems
        for file in files {
            await storage.remove(batchReference: file.reference)
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let dataItems = await storage.read().dataItems
        #expect(dataItems.count == 1)
    }
    
    // MARK: - Memory Storage Tests
    @Test("given memory storage, when writing an event, then event count increases after rollover")
    func writeEventToMemory() async {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.rollover()
        let existingItems = await storage.read().dataItems
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        #expect(resultItems.count > existingItems.count)
    }
    
    @Test("given memory storage with written events, when reading them, then events are accessible")
    func readEventFromMemory() async {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        #expect(!resultItems.isEmpty)
    }
    
    @Test("given memory storage with stored events, when removing all items, then storage becomes empty")
    func removeEventFromMemory() async {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        for item in resultItems {
            await storage.remove(batchReference: item.reference)
        }
        
        let dataItems = await storage.read().dataItems
        #expect(dataItems.isEmpty)
    }
    
    @Test("given memory storage with multiple events, when calling removeAll, then all events are cleared")
    func removeAllEventsFromMemory() async {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        // Write multiple events
        await storage.write(event: eventJson)
        await storage.rollover()
        await storage.write(event: eventJson)
        await storage.rollover()
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        #expect(!resultItems.isEmpty)
        
        // Remove all events using removeAll method
        await storage.removeAll()
        
        let dataItemsAfterRemoval = await storage.read().dataItems
        #expect(dataItemsAfterRemoval.isEmpty)
    }
    
    @Test("given memory storage, when performing rollover operation, then events are properly batched")
    func rolloverEventInMemory() async {
        let storage = MockProvider.clientWithMemoryStorage.configuration.storage
        guard let eventJson = MockProvider.simpleTrackEvent.jsonString else {
            Issue.record("Failed to create event JSON")
            return
        }
        
        await storage.rollover()
        let resultItems1 = await storage.read().dataItems
        for item in resultItems1 {
            await storage.remove(batchReference: item.reference)
        }
        
        await storage.write(event: eventJson)
        let resultItems2 = await storage.read().dataItems
        #expect(resultItems2.isEmpty)
        
        await storage.rollover()
        let resultItems3 = await storage.read().dataItems
        #expect(!resultItems3.isEmpty)
    }
}
