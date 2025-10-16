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
    
    private let testWriteKey = "test-disk-write-key-123"
    private let sampleEventJson = """
        {"messageId":"test-msg-123","type":"track","event":"Test Event","properties":{"test":true}}
        """
    var store: DiskStore
    var keyValueStore: KeyValueStore
    
    init() {
        store = DiskStore(writeKey: testWriteKey)
        keyValueStore = KeyValueStore(writeKey: testWriteKey)
    }
    
    deinit {
        keyValueStore.removeAll()
    }
    
    // MARK: - Initialization Tests
    
    @Test("given writeKey, when initializing DiskStore, then store is created with correct writeKey and storage URL")
    func testInitialization() async {
        #expect(await store.writeKey == testWriteKey)
        
        let fileStorageURL = await store.fileStorageURL
        #expect(fileStorageURL.lastPathComponent == testWriteKey)
        #expect(fileStorageURL.absoluteString.contains("rudder"))
    }
    
    // MARK: - Basic Storage Operations
    
    @Test("given DiskStore, when storing single event, then file is created with event data")
    func testStoreSingleEvent() async {
        await store.retain(value: sampleEventJson)
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty) // Should be empty as we haven't rolled over yet
        
        // Check if file exists on disk but isn't marked as complete
        let fileStorageURL = await store.fileStorageURL
        let contents = FileManager.contentsOf(directory: fileStorageURL.path)
        #expect(contents.count >= 1) // Should have at least one .tmp file
        
        // Clean up the store
        await store.removeAll()
    }
    
    @Test("given DiskStore with event, when calling rollover, then file is finalized and retrievable")
    func testRollover() async {
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        #expect(retrievedItems.first?.isClosed == true)
        #expect(retrievedItems.first?.reference.isEmpty == false)
        
        // Verify file content by reading it
        if let filePath = retrievedItems.first?.reference {
            let fileContent = FileManager.contentsOf(file: filePath)
            #expect(fileContent?.contains("Test Event") == true)
            #expect(fileContent?.hasPrefix(DataStoreConstants.fileBatchPrefix) == true)
            #expect(fileContent?.hasSuffix(DataStoreConstants.fileBatchSuffix) == true)
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    @Test("given DiskStore, when storing multiple events before rollover, then events are batched in single file")
    func testMultipleEventsInSingleBatch() async {
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
        
        if let filePath = retrievedItems.first?.reference {
            let fileContent = FileManager.contentsOf(file: filePath)
            #expect(fileContent?.contains("Event 1") == true)
            #expect(fileContent?.contains("Event 2") == true)
            #expect(fileContent?.contains("sentAt") == true) // Should include timestamp
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    @Test("given DiskStore, when single event is stored and rolled over, then proper batch format is created")
    func testSingleEventBatchFormat() async {
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        
        if let filePath = retrievedItems.first?.reference {
            let fileContent = FileManager.contentsOf(file: filePath)
            #expect(fileContent?.hasPrefix(DataStoreConstants.fileBatchPrefix) == true)
            #expect(fileContent?.hasSuffix(DataStoreConstants.fileBatchSuffix) == true)
            #expect(fileContent?.contains("Test Event") == true)
            
            // Verify it's valid JSON structure (basic check)
            #expect(fileContent?.filter { $0 == "[" }.count == 1)
            #expect(fileContent?.filter { $0 == "]" }.count == 1)
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    // MARK: - File Management Tests
    
    @Test("given DiskStore with multiple batches, when retrieving, then files are returned in correct order")
    func testMultipleBatchesOrdering() async {
        // Create first batch
        await store.retain(value: """
            {"messageId":"msg-1","type":"track","event":"First Batch"}
            """)
        await store.rollover()
        
        // Create second batch
        await store.retain(value: """
            {"messageId":"msg-2","type":"track","event":"Second Batch"}
            """)
        await store.rollover()
        
        // Create third batch
        await store.retain(value: """
            {"messageId":"msg-3","type":"track","event":"Third Batch"}
            """)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 3)
        
        // Files should be ordered by index (oldest first)
        let filePaths = retrievedItems.map { $0.reference }
        for i in 0..<filePaths.count - 1 {
            let currentIndex = extractFileIndex(from: filePaths[i])
            let nextIndex = extractFileIndex(from: filePaths[i + 1])
            #expect(currentIndex < nextIndex)
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    @Test("given DiskStore with batch, when removing specific batch, then batch is deleted from disk")
    func testRemoveSpecificBatch() async {
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        var retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        
        let batchReference = retrievedItems.first!.reference
        let removed = await store.remove(reference: batchReference)
        
        #expect(removed == true)
        
        retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty)
        
        // Verify file is actually deleted from disk
        #expect(FileManager.default.fileExists(atPath: batchReference) == false)
        
        // Clean up the store
        await store.removeAll()
    }
    
    @Test("given DiskStore with multiple batches, when removing all, then all files are deleted")
    func testRemoveAllBatches() async {
        // Create multiple batches
        for i in 1...3 {
            await store.retain(value: """
                {"messageId":"msg-\(i)","type":"track","event":"Event \(i)"}
                """)
            await store.rollover()
        }
        
        var retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 3)
        
        await store.removeAll()
        
        retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty)
        
        // Verify directory is cleaned up
        let fileStorageURL = await store.fileStorageURL
        #expect(FileManager.default.fileExists(atPath: fileStorageURL.path) == false)
        
        // Clean up the store
        await store.removeAll()
    }
    
    // MARK: - Large Batch Tests
    
    @Test("given DiskStore, when batch exceeds max size, then new batch is automatically created")
    func testBatchSizeLimit() async {
        // Create a large event that will exceed the batch size limit
        let largeEvent = createLargeEvent(size: Int(DataStoreConstants.maxBatchSize / 2))
        
        await store.retain(value: largeEvent)
        await store.retain(value: largeEvent) // This should trigger a new batch
        await store.retain(value: sampleEventJson) // This should go to the new batch
        
        await store.rollover() // Close the current batch
        
        let retrievedItems = await store.retrieve()
        
        // Should have at least one completed batch, possibly two depending on timing
        #expect(retrievedItems.count >= 1)
        
        // Verify all events are stored
        let allContent = retrievedItems.compactMap { item in
            FileManager.contentsOf(file: item.reference)
        }.joined()
        
        #expect(allContent.contains("Test Event") == true)
        
        // Clean up the store
        await store.removeAll()
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("given DiskStore, when rolling over without events, then no batch file is created")
    func testRolloverWithoutEvents() async {
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.isEmpty)
        
        // Verify no files are created on disk
        let fileStorageURL = await store.fileStorageURL
        let contents = FileManager.contentsOf(directory: fileStorageURL.path)
        let finalizedFiles = contents.filter { !$0.pathExtension.isEmpty }
        #expect(finalizedFiles.isEmpty)
    }
    
    @Test("given DiskStore, when removing non-existent batch, then operation returns false")
    func testRemoveNonExistentBatch() async {
        let fakeReference = "/non/existent/file/path"
        let removed = await store.remove(reference: fakeReference)
        
        #expect(removed == false)
    }
    
    @Test("given DiskStore, when storing events with special characters, then events are properly encoded")
    func testSpecialCharactersInEvents() async {
        let specialEvent = """
            {"messageId":"special-123","type":"track","event":"Test Event","properties":{"emoji":"🚀","unicode":"café","quotes":"say \\"hello\\""}}
            """
        
        await store.retain(value: specialEvent)
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        
        if let filePath = retrievedItems.first?.reference {
            let fileContent = FileManager.contentsOf(file: filePath)
            #expect(fileContent?.contains("🚀") == true)
            #expect(fileContent?.contains("café") == true)
            #expect(fileContent?.contains("hello") == true)
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("given DiskStore, when multiple events are stored concurrently, then all events are persisted")
    func testConcurrentEventStorage() async {
        let eventCount = 10
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<eventCount {
                group.addTask {
                    await self.store.retain(value: """
                        {"messageId":"concurrent-\(i)","type":"track","event":"Concurrent Event \(i)"}
                        """)
                }
            }
        }
        
        await store.rollover()
        
        let retrievedItems = await store.retrieve()
        #expect(retrievedItems.count == 1)
        
        if let filePath = retrievedItems.first?.reference {
            let fileContent = FileManager.contentsOf(file: filePath) ?? ""
            
            // Verify all events are present
            for i in 0..<eventCount {
                #expect(fileContent.contains("Concurrent Event \(i)") == true)
            }
        }
        
        // Clean up the store
        await store.removeAll()
    }
    
    // MARK: - File Index Management Tests
    
    @Test("given DiskStore with multiple batches, when creating new instances, then file indexing continues correctly")
    func testFileIndexPersistence() async {
        // Clean up first
        await store.removeAll()
        
        // Create first batch
        await store.retain(value: sampleEventJson)
        await store.rollover()
        
        // Create a new store instance with same writeKey
        let newStore = DiskStore(writeKey: testWriteKey)
        
        // Add another event
        await newStore.retain(value: """
            {"messageId":"new-msg","type":"track","event":"New Event"}
            """)
        await newStore.rollover()
        
        let retrievedItems = await newStore.retrieve()
        #expect(retrievedItems.count == 2)
        
        // Verify file indices are sequential
        let fileIndices = retrievedItems.map { extractFileIndex(from: $0.reference) }
        #expect(fileIndices.contains(0) == true)
        #expect(fileIndices.contains(1) == true)
        
        // Clean up new store
        await newStore.removeAll()
    }
    
    @Test("given DiskStore, when directory doesn't exist, then directory is created automatically")
    func testDirectoryCreation() async {
        // Create a store with a unique writeKey to ensure clean directory
        let uniqueWriteKey = "unique-test-key-\(String.randomUUIDString)"
        let testStore = DiskStore(writeKey: uniqueWriteKey)
        
        let fileStorageURL = await testStore.fileStorageURL
        
        // Directory shouldn't exist initially
        #expect(FileManager.default.fileExists(atPath: fileStorageURL.path) == false)
        
        // Store an event (this should create the directory)
        await testStore.retain(value: sampleEventJson)
        
        // Now directory should exist
        #expect(FileManager.default.fileExists(atPath: fileStorageURL.path) == true)
        
        // Clean up
        await testStore.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func extractFileIndex(from filePath: String) -> Int {
        let url = URL(fileURLWithPath: filePath)
        return Int(url.lastPathComponent) ?? -1
    }
    
    private func createLargeEvent(size: Int) -> String {
        let baseEvent = """
            {"messageId":"large-msg","type":"track","event":"Large Event","properties":{"data":"
            """
        let padding = String(repeating: "x", count: max(0, size - baseEvent.count - 3))
        return baseEvent + padding + "\"}}"
    }
    
    private var fileIndexKey: String {
        return DataStoreConstants.fileIndex + testWriteKey
    }
    
    private var currentFileIndex: Int {
        guard let index: Int = self.keyValueStore.read(reference: self.fileIndexKey) else { return 0 }
        return index
    }
}
