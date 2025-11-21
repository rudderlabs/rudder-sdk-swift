//
//  MemoryStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/10/25.
//

import Testing
@testable import RudderStackAnalytics

// MARK: - MemoryStore Unit Tests
@Suite("MemoryStore Unit Tests")
class MemoryStoreTests {
    
    private let testWriteKey = "test-write-key-\(String.randomUUIDString)"
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    var store: MemoryStore
    
    init() {
        store = MemoryStore(writeKey: testWriteKey)
    }
    
    // MARK: - Initialization Tests
    
    @Test("when initializing MemoryStore, then store is created with correct writeKey")
    func testInitialization() async {
        #expect(await store.writeKey == testWriteKey)
        #expect(await store.dataItems.isEmpty)
    }
    
    // MARK: - Basic Storage Operations
    
    @Test("when storing single event, then event is added to current batch")
    func testStoreSingleEvent() async {
        await store.retain(value: sampleEventJson)
        
        let dataItems = await store.dataItems
        #expect(dataItems.count == 1)
        #expect(dataItems.first?.batch.contains("Test Event") ?? false)
        #expect(!(dataItems.first?.isClosed ?? true))
    }
    
    @Test("given MemoryStore with event, when calling rollover, then batch is finalized")
    func testRollover() async {
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        #expect(retrievedItems.first?.isClosed ?? false)
        #expect(retrievedItems.first?.batch.hasSuffix(DataStoreConstants.fileBatchSuffix) ?? false)
    }
    
    @Test("when storing multiple events before rollover, then events are batched together")
    func testMultipleEventsInBatch() async {
        let event1 = """
            {"messageId":"msg-1","type":"track","event":"Event 1"}
            """
        let event2 = """
            {"messageId":"msg-2","type":"track","event":"Event 2"}
            """
        
        await store.retain(value: event1)
        await store.retain(value: event2)
        
        let dataItems = await store.dataItems
        #expect(dataItems.count == 1)
        #expect(dataItems.first?.batch.contains("Event 1") ?? false)
        #expect(dataItems.first?.batch.contains("Event 2") ?? false)
    }
    
    // MARK: - Batch Management Tests
    
    @Test("given MemoryStore with completed batch, when retrieving items, then only closed batches are returned")
    func testRetrieveOnlyClosedBatches() async {
        // Add event and rollover (closed batch)
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        // Add another event but don't rollover (open batch)
        await store.retain(value: sampleEventJson)
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1) // Only the closed batch
        #expect(retrievedItems.first?.isClosed ?? false)
        
        let allDataItems = await store.dataItems
        #expect(allDataItems.count == 2) // Both open and closed batches exist internally
    }
    
    @Test("given MemoryStore with multiple batches, when retrieving, then all closed batches are returned")
    func testRetrieveMultipleClosedBatches() async {
        // Create first batch
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        // Create second batch
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        // Create third batch
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 3)
        
        for item in retrievedItems {
            #expect(item.isClosed)
            #expect(item.batch.hasSuffix(DataStoreConstants.fileBatchSuffix))
        }
    }
    
    // MARK: - Removal Operations Tests
    
    @Test("given MemoryStore with batches, when removing by reference, then specific batch is removed")
    func testRemoveByReference() async {
        // Create two batches
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let itemsBeforeRemoval = await store.retrieve()
        #expect(itemsBeforeRemoval.count == 2)
        
        // Remove first batch
        guard let referenceToRemove = itemsBeforeRemoval.first?.reference else {
            Issue.record("Expected at least one batch before removal")
            return
        }
        
        let wasRemoved = await store.remove(reference: referenceToRemove)
        #expect(wasRemoved)
        
        let itemsAfterRemoval = await store.retrieve()
        #expect(itemsAfterRemoval.count == 1)
        #expect(itemsAfterRemoval.first?.reference != referenceToRemove)
    }
    
    @Test("when removing non-existent reference, then returns false", arguments: ["non-existent-reference"])
    func testRemoveNonExistentReference(_ nonExistentReference: String) async {
        let wasRemoved = await store.remove(reference: nonExistentReference)
        #expect(!wasRemoved)
    }
    
    @Test("given MemoryStore with multiple batches, when calling removeAll, then all batches are cleared")
    func testRemoveAll() async {
        // Create multiple batches
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        await store.retain(value: sampleEventJson) // Current batch
        
        let itemsBeforeRemoval = await store.dataItems
        #expect(itemsBeforeRemoval.count == 3)
        
        await store.removeAll()
        
        let itemsAfterRemoval = await store.dataItems
        #expect(itemsAfterRemoval.isEmpty)
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty)
    }
    
    // MARK: - Batch Size and Overflow Tests
    
    @Test("when adding events exceeding batch size, then automatic rollover occurs")
    func testBatchSizeLimit() async {
        // Add normal event first
        await store.retain(value: sampleEventJson)
        
        let itemsAfterFirst = await store.dataItems
        #expect(itemsAfterFirst.count == 1)
        
        // Add multiple medium-sized events to exceed the 500KB batch limit
        // Each event is ~2KB, so we need about 250+ events to exceed 500KB
        for i in 1...260 {
            let mediumEvent = """
                {"messageId":"msg-\(i)","type":"track","event":"Test Event \(i)","properties":{"data":"\(String(repeating: "x", count: 2000))"}}
                """
            await store.retain(value: mediumEvent)
        }
        
        let itemsAfterMany = await store.dataItems
        // Should have at least 2 items due to automatic rollover when batch size is exceeded
        #expect(itemsAfterMany.count >= 2)
        
        // Verify that rollover actually happened by checking that we have closed batches
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count >= 1)
        #expect(retrievedItems.first?.isClosed ?? false)
    }
    
    // MARK: - Batch Format Tests
    
    @Test("when events are batched, then proper JSON batch format is maintained")
    func testBatchJsonFormat() async {
        let event1 = """
            {"messageId":"msg-1","type":"track","event":"Event 1"}
            """
        let event2 = """
            {"messageId":"msg-2","type":"track","event":"Event 2"}
            """
        
        await store.retain(value: event1)
        await store.retain(value: event2)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        
        guard let batchContent = retrievedItems.first?.batch else {
            Issue.record("Expected a batch after rollover")
            return
        }
        #expect(batchContent.hasPrefix(DataStoreConstants.fileBatchPrefix))
        #expect(batchContent.hasSuffix(DataStoreConstants.fileBatchSuffix))
        #expect(batchContent.contains("Event 1"))
        #expect(batchContent.contains("Event 2"))
        #expect(batchContent.contains("sentAt")) // Should include timestamp
    }
    
    @Test("when single event is stored and rolled over, then proper batch format is created")
    func testSingleEventBatchFormat() async {
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        guard let batchContent = retrievedItems.first?.batch else {
            Issue.record("Expected a batch after rollover")
            return
        }
        
        #expect(batchContent.hasPrefix(DataStoreConstants.fileBatchPrefix))
        #expect(batchContent.hasSuffix(DataStoreConstants.fileBatchSuffix))
        #expect(batchContent.contains("Test Event"))
        
        // Verify it's valid JSON structure (basic check)
        #expect(batchContent.filter { $0 == "[" }.count == 1)
        #expect(batchContent.filter { $0 == "]" }.count == 1)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("when rolling over without events, then no batch is created")
    func testRolloverWithoutEvents() async {
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty)
        
        let allDataItems = await store.dataItems
        #expect(allDataItems.isEmpty)
    }
}
