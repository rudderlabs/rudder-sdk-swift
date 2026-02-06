//
//  DiskStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/10/25.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

// MARK: - DiskStore Unit Tests
@Suite("DiskStore Unit Tests")
class DiskStoreTests {
    
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    private let testEventName = "Test Event"
    
    var storage: MockStorage
    
    init() {
        storage = MockStorage(storageMode: .disk)
    }
    
    // MARK: - Initialization Tests
    
    @Test("when initializing storage, then store is created empty")
    func testInitialization() async {
        #expect(storage.currentBatchEventCount == 0)
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    // MARK: - Basic Storage Operations
    
    @Test("when storing single event, then event is stored in current batch")
    func testStoreSingleEvent() async {
        await storage.write(event: sampleEventJson)
        
        // Event is in the current batch, not yet rolled over
        #expect(storage.currentBatchEventCount == 1)
        
        // Clean up the store
        await storage.removeAll()
    }
    
    @Test("given storage with event, when calling rollover, then batch is finalized and retrievable")
    func testRollover() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        #expect(result.dataItems.first?.isClosed ?? false)
        
        // Verify batch content
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains(testEventName))
        
        // Clean up the store
        await storage.removeAll()
    }
    
    @Test("when storing multiple events before rollover, then events are batched in single batch")
    func testMultipleEventsInSingleBatch() async {
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
        
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains("Event 1"))
        #expect(batchContent.contains("Event 2"))
        
        // Clean up the store
        await storage.removeAll()
    }
    
    @Test("when single event is stored and rolled over, then proper batch format is created")
    func testSingleEventBatchFormat() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains(testEventName))
        
        // Clean up the store
        await storage.removeAll()
    }
    
    // MARK: - Batch Management Tests
    
    @Test("given storage with multiple batches, when retrieving, then all batches are returned in order")
    func testMultipleBatchesOrdering() async {
        // Create first batch
        await storage.write(event: """
            {"messageId":"msg-1","type":"track","event":"First Batch"}
            """)
        await storage.rollover()
        
        // Create second batch
        await storage.write(event: """
            {"messageId":"msg-2","type":"track","event":"Second Batch"}
            """)
        await storage.rollover()
        
        // Create third batch
        await storage.write(event: """
            {"messageId":"msg-3","type":"track","event":"Third Batch"}
            """)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 3)
        
        // Clean up the store
        await storage.removeAll()
    }
    
    @Test("given storage with batch, when removing specific batch, then batch is deleted")
    func testRemoveSpecificBatch() async {
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        var result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        guard let batchReference = result.dataItems.first?.reference else {
            Issue.record("Expected at least one batch reference")
            return
        }
        
        let removed = await storage.remove(batchReference: batchReference)
        #expect(removed)
        
        result = await storage.read()
        #expect(result.dataItems.isEmpty)
        
        // Clean up the store
        await storage.removeAll()
    }
    
    @Test("given storage with multiple batches, when removing all, then all batches are deleted")
    func testRemoveAllBatches() async {
        // Create multiple batches
        for i in 1...3 {
            await storage.write(event: """
                {"messageId":"msg-\(i)","type":"track","event":"Event \(i)"}
                """)
            await storage.rollover()
        }
        
        var result = await storage.read()
        #expect(result.dataItems.count == 3)
        
        await storage.removeAll()
        
        result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("when rolling over without events, then no batch is created")
    func testRolloverWithoutEvents() async {
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.isEmpty)
    }
    
    @Test("when removing non-existent batch, then operation returns false", arguments: ["/non/existent/file/path"])
    func testRemoveNonExistentBatch(_ fakeReference: String) async {
        let removed = await storage.remove(batchReference: fakeReference)
        #expect(!removed)
    }
    
    @Test("when storing events with special characters, then events are properly encoded")
    func testSpecialCharactersInEvents() async {
        let specialEvent = """
            {"messageId":"special-123","type":"track","event":"Test Event","properties":{"emoji":"🚀","unicode":"café","quotes":"say \\"hello\\""}}
            """
        
        await storage.write(event: specialEvent)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.first?.batch ?? ""
        #expect(batchContent.contains("🚀"))
        #expect(batchContent.contains("café"))
        #expect(batchContent.contains("hello"))
        
        // Clean up the store
        await storage.removeAll()
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("when multiple events are stored concurrently, then all events are persisted")
    func testConcurrentEventStorage() async {
        let eventCount = 10
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<eventCount {
                group.addTask {
                    await self.storage.write(event: """
                        {"messageId":"concurrent-\(i)","type":"track","event":"Concurrent Event \(i)"}
                        """)
                }
            }
        }
        
        #expect(storage.totalEventCount == eventCount)
        
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.first?.batch ?? ""
        // Verify all events are present
        for i in 0..<eventCount {
            #expect(batchContent.contains("Concurrent Event \(i)"))
        }
        
        // Clean up the store
        await storage.removeAll()
    }
    
    // MARK: - Batch Size Tests
    
    @Test("when adding many events, then all events are stored correctly")
    func testBatchSizeLimit() async {
        // Add multiple events to simulate batch growth
        let largeEvent = """
            {"messageId":"large-msg","type":"track","event":"Large Event","properties":{"data":"\(String(repeating: "x", count: 1000))"}}
            """
        
        await storage.write(event: largeEvent)
        await storage.write(event: largeEvent)
        await storage.write(event: sampleEventJson)
        
        #expect(storage.totalEventCount == 3)
        
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count >= 1)
        
        let allContent = result.dataItems.map { $0.batch }.joined()
        #expect(allContent.contains(testEventName))
        
        // Clean up the store
        await storage.removeAll()
    }
    
    // MARK: - Batch Index/Persistence Tests
    
    @Test("given storage with multiple batches, then batch count is tracked correctly")
    func testBatchCountTracking() async {
        // Create first batch
        await storage.write(event: sampleEventJson)
        await storage.rollover()
        
        // Create second batch
        await storage.write(event: """
            {"messageId":"new-msg","type":"track","event":"New Event"}
            """)
        await storage.rollover()
        
        let result = await storage.read()
        #expect(result.dataItems.count == 2)
        #expect(storage.batchCount == 2)
        
        // Clean up
        await storage.removeAll()
    }
    
    @Test("when directory/storage doesn't have data, then storage starts empty")
    func testEmptyStorageStart() async {
        let freshStorage = MockStorage(storageMode: .disk)
        
        let result = await freshStorage.read()
        #expect(result.dataItems.isEmpty)
        #expect(freshStorage.currentBatchEventCount == 0)
    }
}
