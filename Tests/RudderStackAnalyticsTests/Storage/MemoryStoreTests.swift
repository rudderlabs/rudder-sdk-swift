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
    
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    var storage: MockStorage
    
    init() {
        storage = MockStorage(storageMode: .memory)
    }
    
    // MARK: - Initialization Tests
    
    @Test("when initializing storage, then store is created empty")
    func testInitialization() async {
        #expect(storage.currentBatchEventCount == 0)
        #expect(storage.totalEventCount == 0)
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    // MARK: - Basic Storage Operations
    
    @Test("when storing single event, then event is added to current batch")
    func testStoreSingleEvent() async {
        await storage.write(event: sampleEventJson)
        
        // Event is in the current batch, not yet rolled over
        #expect(storage.currentBatchEventCount == 1)
    }
    
    @Test("given storage with event, when calling rollover, then batch is finalized")
    func testRollover() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.isClosed ?? false)
    }
    
    @Test("when storing multiple events before rollover, then events are batched together")
    func testMultipleEventsInBatch() async {
        let event1 = """
            {"messageId":"msg-1","type":"track","event":"Event 1"}
            """
        let event2 = """
            {"messageId":"msg-2","type":"track","event":"Event 2"}
            """
        
        await storage.write(event: event1)
        await storage.write(event: event2)

        #expect(storage.currentBatchEventCount == 2)

        await storage.rollover()

        let result = await storage.read()
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains("Event 1"))
        #expect(batchContent.contains("Event 2"))
    }
    
    // MARK: - Batch Management Tests
    
    @Test("given storage with completed batch, when retrieving items, then only closed batches are returned")
    func testRetrieveOnlyClosedBatches() async {
        // Add event and rollover (closed batch)
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Add another event but don't rollover (open batch)
        await storage.write(event: sampleEventJson)
        
        // read() should only return the closed batch, not the open one
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.isClosed ?? false)

        #expect(storage.currentBatchEventCount == 1)
    }
    
    @Test("given storage with multiple batches, when retrieving, then all closed batches are returned")
    func testRetrieveMultipleClosedBatches() async {
        // Create first batch
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Create second batch
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Create third batch
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 3)
        
        for item in result.dataItems {
            #expect(item.isClosed)
        }
    }
    
    // MARK: - Removal Operations Tests
    
    @Test("given storage with batches, when removing by reference, then specific batch is removed")
    func testRemoveByReference() async {
        // Create two batches
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let itemsBeforeRemoval = await storage.read()
        #expect(itemsBeforeRemoval.dataItems.count == 2)
        
        // Remove first batch
        guard let referenceToRemove = itemsBeforeRemoval.dataItems.first?.reference else {
            Issue.record("Expected at least one batch before removal")
            return
        }
        
        let wasRemoved = await storage.remove(batchReference: referenceToRemove)
        #expect(wasRemoved)
        
        let itemsAfterRemoval = await storage.read()
        #expect(itemsAfterRemoval.dataItems.count == 1)
        #expect(itemsAfterRemoval.dataItems.first?.reference != referenceToRemove)
    }
    
    @Test("when removing non-existent reference, then returns false", arguments: ["non-existent-reference"])
    func testRemoveNonExistentReference(_ nonExistentReference: String) async {
        let wasRemoved = await storage.remove(batchReference: nonExistentReference)
        #expect(!wasRemoved)
    }
    
    @Test("given storage with multiple batches, when calling removeAll, then all batches are cleared")
    func testRemoveAll() async {
        // Create multiple batches
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        await storage.write(event: sampleEventJson) // Current batch
        
        #expect(storage.totalEventCount == 3)
        
        await storage.removeAll()
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
        #expect(storage.currentBatchEventCount == 0)
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
        
        await storage.write(event: event1)
        await storage.write(event: event2)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        guard let batchContent = result.dataItems.first?.batch else {
            Issue.record("Expected a batch after rollover")
            return
        }
        
        #expect(batchContent.contains("Event 1"))
        #expect(batchContent.contains("Event 2"))
    }
    
    @Test("when single event is stored and rolled over, then proper batch format is created")
    func testSingleEventBatchFormat() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        guard let batchContent = result.dataItems.first?.batch else {
            Issue.record("Expected a batch after rollover")
            return
        }
        
        #expect(batchContent.contains("Test Event"))
    }
    
    // MARK: - Batch Size Tests
    
    @Test("when adding many events, then all events are stored correctly")
    func testBatchSizeLimit() async {
        // Add normal event first
        await storage.write(event: sampleEventJson)
        
        #expect(storage.currentBatchEventCount == 1)
        
        // Add multiple events
        for i in 1...10 {
            let event = """
                {"messageId":"msg-\(i)","type":"track","event":"Test Event \(i)","properties":{"data":"value"}}
                """
            await storage.write(event: event)
        }
        
        #expect(storage.totalEventCount == 11)
    }
    
    @Test("when adding events exceeding batch size, then automatic rollover occurs")
    func testBatchSizeLimitAutoRollover() async {
        // Create a large event that is about 3/4 of maxBatchSize (500 KB),
        // so two events will clearly exceed the limit and trigger auto-split
        let largePayload = String(repeating: "x", count: Int(DataStoreConstants.maxBatchSize * 3 / 4))
        let largeEvent = "{\"messageId\":\"large-msg\",\"type\":\"track\",\"event\":\"Large Event\",\"properties\":{\"data\":\"\(largePayload)\"}}"

        // First large event fits in the batch
        await storage.write(event: largeEvent)
        // Second large event should exceed maxBatchSize and trigger auto-split
        await storage.write(event: largeEvent)
        // Small event goes into the new batch
        await storage.write(event: sampleEventJson)

        await storage.rollover()

        let result = await storage.read()

        // Should have at least 2 batches: one closed when size exceeded, one from rollover
        #expect(result.dataItems.count >= 2, "Expected at least 2 batches when batch size limit is exceeded, got \(result.dataItems.count)")

        // Verify all events are stored across batches
        let allContent = result.dataItems.map { $0.batch }.joined()
        #expect(allContent.contains("Large Event"))
        #expect(allContent.contains("Test Event"))

        // Clean up
        await storage.removeAll()
    }

    // MARK: - Edge Cases Tests
    
    @Test("when rolling over without events, then no batch is created")
    func testRolloverWithoutEvents() async {
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
}
