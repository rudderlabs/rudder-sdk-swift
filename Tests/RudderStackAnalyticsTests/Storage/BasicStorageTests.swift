//
//  BasicStorageTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/10/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

// MARK: - BasicStorage Unit Tests
@Suite("BasicStorage Unit Tests")
class BasicStorageTests {
    
    private let testWriteKey = "test-basic-storage-key-\(String.randomUUIDString)"
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    var storage: BasicStorage
    
    init() {
        storage = BasicStorage(writeKey: testWriteKey, storageMode: .memory)
    }
    
    // MARK: - KeyValueStorage Tests
    
    @Test(
        "when writing values of different types, then values are persisted correctly",
        arguments: [
            ("test_string_key", TestArgumentValue.string("test_string_value")),
            ("test_int_key", TestArgumentValue.integer(42)),
            ("test_bool_key", TestArgumentValue.boolean(true)),
            ("test_object_key", TestArgumentValue.object(TestObject(id: "123", name: "Test Object", count: 5)))
        ]
    )
    func testKeyValueStorage(key: String, value: TestArgumentValue) async {
        switch value {
        case .string(let stringValue):
            storage.write(value: stringValue, key: key)
            let retrieved: String? = storage.read(key: key)
            #expect(retrieved == stringValue)
            
        case .integer(let intValue):
            storage.write(value: intValue, key: key)
            let retrieved: Int? = storage.read(key: key)
            #expect(retrieved == intValue)
            
        case .boolean(let boolValue):
            storage.write(value: boolValue, key: key)
            let retrieved: Bool? = storage.read(key: key)
            #expect(retrieved == boolValue)
            
        case .object(let objectValue):
            storage.write(value: objectValue, key: key)
            let retrieved: TestObject? = storage.read(key: key)
            #expect(retrieved == objectValue)
        }
    }
    
    @Test("when reading non-existent key, then nil is returned")
    func testKeyValueReadNonExistentKey() async {
        let nonExistentKey = "non_existent_key"
        let retrievedValue: String? = storage.read(key: nonExistentKey)
        
        #expect(retrievedValue == nil)
    }
    
    @Test("given BasicStorage with stored value, when removing key, then value is deleted")
    func testKeyValueRemove() async {
        let key = "test_remove_key"
        let value = "test_value_to_remove"
        storage.write(value: value, key: key)
        
        storage.remove(key: key)
        
        let retrievedValue: String? = storage.read(key: key)
        #expect(retrievedValue == nil)
    }
    
    @Test("when writing multiple key-value pairs, then all values are persisted correctly")
    func testMultipleKeyValueOperations() async {
        let pairs = [
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3")
        ]
        
        for (key, value) in pairs {
            storage.write(value: value, key: key)
        }
        
        for (key, expectedValue) in pairs {
            let retrievedValue: String? = storage.read(key: key)
            #expect(retrievedValue == expectedValue)
        }
    }
    
    // MARK: - EventStorage Tests
    
    @Test("when writing single event, then event is stored")
    func testEventStorageSingleEvent() async {
        await storage.write(event: sampleEventJson)
        
        let result = await storage.read()
        // Should be empty until rollover is called
        #expect(result.dataItems.isEmpty)
    }
    
    @Test("given BasicStorage with event, when calling rollover, then event batch is finalized")
    func testEventStorageRollover() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.isClosed == true)
        #expect(result.dataItems.first?.batch.contains("Test Event") == true)
    }
    
    @Test("when storing multiple events before rollover, then events are batched together")
    func testEventStorageMultipleEvents() async {
        let event1 = """
            {"messageId":"msg-1","type":"track","event":"Event 1"}
            """
        let event2 = """
            {"messageId":"msg-2","type":"track","event":"Event 2"}
            """
        let event3 = """
            {"messageId":"msg-3","type":"track","event":"Event 3"}
            """
        
        await storage.write(event: event1)
        await storage.write(event: event2)
        await storage.write(event: event3)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains("Event 1") == true)
        #expect(batchContent.contains("Event 2") == true)
        #expect(batchContent.contains("Event 3") == true)
    }
    
    @Test("given BasicStorage with multiple batches, when retrieving events, then all batches are returned")
    func testEventStorageMultipleBatches() async {
        // Create first batch
        await storage.write(event: """
            {"messageId":"batch1-msg","type":"track","event":"Batch 1 Event"}
            """)
        await storage.rollover()
        
        // Create second batch
        await storage.write(event: """
            {"messageId":"batch2-msg","type":"track","event":"Batch 2 Event"}
            """)
        await storage.rollover()
        
        // Create third batch
        await storage.write(event: """
            {"messageId":"batch3-msg","type":"track","event":"Batch 3 Event"}
            """)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 3)
        
        // then all batches are closed
        for dataItem in result.dataItems {
            #expect(dataItem.isClosed == true)
        }
    }
    
    @Test("given BasicStorage with event batch, when removing specific batch, then batch is deleted")
    func testEventStorageRemoveSpecificBatch() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        var result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        guard let batchReference = result.dataItems.first?.reference else {
            Issue.record("Expected at least one data item")
            return
        }
        let removed = await storage.remove(batchReference: batchReference)
        
        #expect(removed == true)
        
        result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    @Test("when removing non-existent batch, then operation returns false")
    func testEventStorageRemoveNonExistentBatch() async {
        let fakeBatchReference = "non-existent-batch-reference"
        let removed = await storage.remove(batchReference: fakeBatchReference)
        
        #expect(removed == false)
    }
    
    @Test("when calling rollover without events, then no batch is created")
    func testEventStorageRolloverWithoutEvents() async {
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    // MARK: - Combined Storage Operations Tests
    
    @Test("when using both key-value and event storage, then both work independently")
    func testCombinedStorageOperations() async {
        // Store key-value data
        let key = "combined_test_key"
        let value = "combined_test_value"
        storage.write(value: value, key: key)
        
        // Store event data
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Verify key-value storage
        let retrievedValue: String? = storage.read(key: key)
        #expect(retrievedValue == value)
        
        // Verify event storage
        let eventResult = await storage.read()
        #expect(eventResult.dataItems.count == 1)
        #expect(eventResult.dataItems.first?.batch.contains("Test Event") == true)
    }
    
    @Test("given BasicStorage with mixed data, when calling removeAll, then all data is cleared")
    func testRemoveAllData() async {
        // Store key-value data
        storage.write(value: "test_value", key: "test_key")
        
        // Store event data
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Remove all data
        await storage.removeAll()
        
        // Verify all data is cleared
        let clearedKeyValue: String? = storage.read(key: "test_key")
        #expect(clearedKeyValue == nil)
        
        let clearedEventResult = await storage.read()
        #expect(clearedEventResult.dataItems.isEmpty)
    }
    
    
    // MARK: - Edge Cases Tests
    
    @Test("when storing empty string as value, then empty string is retrieved")
    func testEmptyStringStorage() async {
        let key = "empty_string_key"
        let value = ""
        
        storage.write(value: value, key: key)
        let retrievedValue: String? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("when storing empty event, then event is handled correctly")
    func testEmptyEventStorage() async {
        let emptyEvent = ""
        
        await storage.write(event: emptyEvent)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.batch.contains(DataStoreConstants.fileBatchPrefix) == true)
    }
    
    @Test("when storing events with special characters, then events are preserved correctly")
    func testSpecialCharactersInEvents() async {
        let specialEvent = """
            {"messageId":"special-123","type":"track","event":"Test Event","properties":{"emoji":"🚀","unicode":"café","quotes":"say \\"hello\\""}}
            """
        
        await storage.write(event: specialEvent)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains("🚀") == true)
        #expect(batchContent.contains("café") == true)
        #expect(batchContent.contains("hello") == true)
    }
    
    @Test("when overwriting existing key, then new value replaces old value")
    func testKeyValueOverwrite() async {
        let key = "overwrite_key"
        let originalValue = "original_value"
        let newValue = "new_value"
        
        // Store original value
        storage.write(value: originalValue, key: key)
        var retrievedValue: String? = storage.read(key: key)
        #expect(retrievedValue == originalValue)
        
        // Overwrite with new value
        storage.write(value: newValue, key: key)
        retrievedValue = storage.read(key: key)
        #expect(retrievedValue == newValue)
    }
}

struct TestObject: Codable, Equatable {
    let id: String
    let name: String
    let count: Int
}

enum TestArgumentValue {
    case string(String)
    case integer(Int)
    case boolean(Bool)
    case object(TestObject)
}
