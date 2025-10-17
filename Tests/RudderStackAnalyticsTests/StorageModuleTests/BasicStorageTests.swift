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
    
    private let testWriteKey = "test-basic-storage-key-123"
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    var storage: BasicStorage
    
    init() {
        storage = BasicStorage(writeKey: testWriteKey, storageMode: .memory)
    }
    
    // MARK: - KeyValueStorage Tests
    
    @Test("given BasicStorage, when writing string value, then value is persisted correctly")
    func testKeyValueStringStorage() async {
        let key = "test_string_key"
        let value = "test_string_value"
        
        storage.write(value: value, key: key)
        let retrievedValue: String? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given BasicStorage, when writing integer value, then value is persisted correctly")
    func testKeyValueIntegerStorage() async {
        let key = "test_int_key"
        let value = 42
        
        storage.write(value: value, key: key)
        let retrievedValue: Int? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given BasicStorage, when writing boolean value, then value is persisted correctly")
    func testKeyValueBooleanStorage() async {
        let key = "test_bool_key"
        let value = true
        
        storage.write(value: value, key: key)
        let retrievedValue: Bool? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given BasicStorage, when writing codable object, then object is persisted correctly")
    func testKeyValueCodableStorage() async {
        struct TestObject: Codable, Equatable {
            let id: String
            let name: String
            let count: Int
        }
        
        let key = "test_object_key"
        let value = TestObject(id: "123", name: "Test Object", count: 5)
        
        storage.write(value: value, key: key)
        let retrievedValue: TestObject? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given BasicStorage, when reading non-existent key, then nil is returned")
    func testKeyValueReadNonExistentKey() async {
        let nonExistentKey = "non_existent_key"
        let retrievedValue: String? = storage.read(key: nonExistentKey)
        
        #expect(retrievedValue == nil)
    }
    
    @Test("given BasicStorage with stored value, when removing key, then value is deleted")
    func testKeyValueRemove() async {
        // given...
        let key = "test_remove_key"
        let value = "test_value_to_remove"
        storage.write(value: value, key: key)
        
        // confirm value is stored..
        var retrievedValue: String? = storage.read(key: key)
        #expect(retrievedValue == value)
        
        // when remove the key...
        storage.remove(key: key)
        
        // then value will be deleted..
        retrievedValue = storage.read(key: key)
        #expect(retrievedValue == nil)
    }
    
    @Test("given BasicStorage, when writing multiple key-value pairs, then all values are persisted correctly")
    func testMultipleKeyValueOperations() async {
        let pairs = [
            ("key1", "value1"),
            ("key2", "value2"),
            ("key3", "value3")
        ]
        
        // Write all pairs
        for (key, value) in pairs {
            storage.write(value: value, key: key)
        }
        
        // Verify all pairs
        for (key, expectedValue) in pairs {
            let retrievedValue: String? = storage.read(key: key)
            #expect(retrievedValue == expectedValue)
        }
    }
    
    // MARK: - EventStorage Tests
    
    @Test("given BasicStorage, when writing single event, then event is stored")
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
    
    @Test("given BasicStorage, when storing multiple events before rollover, then events are batched together")
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
        
        // Verify all batches are closed
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
    
    @Test("given BasicStorage, when removing non-existent batch, then operation returns false")
    func testEventStorageRemoveNonExistentBatch() async {
        let fakeBatchReference = "non-existent-batch-reference"
        let removed = await storage.remove(batchReference: fakeBatchReference)
        
        #expect(removed == false)
    }
    
    @Test("given BasicStorage, when calling rollover without events, then no batch is created")
    func testEventStorageRolloverWithoutEvents() async {
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    // MARK: - Combined Storage Operations Tests
    
    @Test("given BasicStorage, when using both key-value and event storage, then both work independently")
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
        
        // Verify data exists
        let keyValue: String? = storage.read(key: "test_key")
        #expect(keyValue == "test_value")
        
        let eventResult = await storage.read()
        #expect(eventResult.dataItems.count == 1)
        
        // Remove all data
        await storage.removeAll()
        
        // Verify all data is cleared
        let clearedKeyValue: String? = storage.read(key: "test_key")
        #expect(clearedKeyValue == nil)
        
        let clearedEventResult = await storage.read()
        #expect(clearedEventResult.dataItems.isEmpty)
    }
    
    
    // MARK: - Edge Cases Tests
    
    @Test("given BasicStorage, when storing empty string as value, then empty string is retrieved")
    func testEmptyStringStorage() async {
        let key = "empty_string_key"
        let value = ""
        
        storage.write(value: value, key: key)
        let retrievedValue: String? = storage.read(key: key)
        
        #expect(retrievedValue == value)
    }
    
    @Test("given BasicStorage, when storing empty event, then event is handled correctly")
    func testEmptyEventStorage() async {
        let emptyEvent = ""
        
        await storage.write(event: emptyEvent)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.batch.contains(DataStoreConstants.fileBatchPrefix) == true)
    }
    
    @Test("given BasicStorage, when storing events with special characters, then events are preserved correctly")
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
    
    @Test("given BasicStorage, when overwriting existing key, then new value replaces old value")
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
