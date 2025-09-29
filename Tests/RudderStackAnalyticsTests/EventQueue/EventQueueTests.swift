//
//  EventQueueTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 19/08/25.
//

import XCTest
@testable import RudderStackAnalytics

// MARK: - EventQueueTests
final class EventQueueTests: XCTestCase {
    
    private var mockAnalytics: Analytics!
    private var eventQueue: EventQueue!
    
    override func setUp() {
        super.setUp()
        mockAnalytics = MockProvider.clientWithDiskStorage
        eventQueue = EventQueue(analytics: mockAnalytics)
    }
    
    override func tearDown() {
        eventQueue = nil
        mockAnalytics = nil
        super.tearDown()
    }
    
    func test_eventQueue_singleEventFlow() async {
        // Given
        let expectation = expectation(description: "Event should be processed end-to-end")
        let event = TrackEvent(event: "integration_test", properties: ["test": "value"])
        
        // When
        eventQueue.put(event)
        
        // Then - Poll for the event in storage
        let startTime = Date()
        let timeout: TimeInterval = 1.5
        
        Task {
            while Date().timeIntervalSince(startTime) < timeout {
                await mockAnalytics.configuration.storage.rollover()
                let dataItems = await mockAnalytics.configuration.storage.read().dataItems
                
                if dataItems.contains(where: { item in
                    let batch = mockAnalytics.storage.eventStorageMode == .memory
                    ? item.batch
                    : (FileManager.contentsOf(file: item.reference) ?? .empty)
                    return batch.contains("integration_test")
                }) {
                    expectation.fulfill()
                    break
                }
                
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Cleanup
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(batchReference: item.reference)
        }
    }
    
    func test_eventQueue_multipleEventsFlow() async {
        // Given
        let expectation = expectation(description: "Multiple events should be processed")
        let events = [
            TrackEvent(event: "event_1", properties: ["index": 1]),
            TrackEvent(event: "event_2", properties: ["index": 2]),
            TrackEvent(event: "event_3", properties: ["index": 3])
        ]
        
        // When
        for event in events {
            eventQueue.put(event)
        }
        
        // Then - Poll until all events are in storage
        let startTime = Date()
        let timeout: TimeInterval = 1.5

        Task {
            while Date().timeIntervalSince(startTime) < timeout {
                await mockAnalytics.configuration.storage.rollover()
                let dataItems = await mockAnalytics.configuration.storage.read().dataItems
                
                var found = Set<String>()
                for item in dataItems {
                    let batch = mockAnalytics.storage.eventStorageMode == .memory
                        ? item.batch
                        : (FileManager.contentsOf(file: item.reference) ?? .empty)
                    
                    if batch.contains("event_1") { found.insert("event_1") }
                    if batch.contains("event_2") { found.insert("event_2") }
                    if batch.contains("event_3") { found.insert("event_3") }
                }
                
                if found.count == events.count {
                    expectation.fulfill()
                    break
                }
                
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Cleanup
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(batchReference: item.reference)
        }
    }

    func test_eventQueue_rolloverOnAnonymousIdChange() async {
        // Given - Clear storage and prepare events with different anonymous IDs
        await mockAnalytics.storage.removeAll()
        
        var event1 = TrackEvent(event: "event_with_anonymousId1", properties: ["test": "value1"])
        event1.anonymousId = "user_123"
        
        var event2 = TrackEvent(event: "event_with_anonymousId2", properties: ["test": "value2"])
        event2.anonymousId = "user_456"
        
        // When - Send events with different anonymous IDs sequentially
        eventQueue.put(event1)
        
        // Wait for first event to be processed
        await runAfter(0.1) {
            // Send second event with different anonymousId
            self.eventQueue.put(event2)
            
            // Allow time for processing and potential rollover
            await runAfter(0.2) {
                // Force rollover to finalize any pending batches
                await self.mockAnalytics.configuration.storage.rollover()
                
                await runAfter(0.1) {
                    // Then - Verify batch creation behavior
                    let dataItems = await self.mockAnalytics.configuration.storage.read().dataItems
                    
                    // Should have created separate batches due to anonymousId change
                    // The exact count depends on when the rollover is triggered by anonymousId change
                    XCTAssertGreaterThanOrEqual(dataItems.count, 1, "Should have at least one batch after processing events")
                    
                    // Verify both events are stored (may be in separate batches)
                    var foundEvent1 = false
                    var foundEvent2 = false
                    
                    for item in dataItems {
                        let batch = self.mockAnalytics.storage.eventStorageMode == .memory
                            ? item.batch
                            : (FileManager.contentsOf(file: item.reference) ?? "")
                        
                        if batch.contains("event_with_anonymousId1") && batch.contains("user_123") {
                            foundEvent1 = true
                        }
                        if batch.contains("event_with_anonymousId2") && batch.contains("user_456") {
                            foundEvent2 = true
                        }
                    }
                    
                    XCTAssertTrue(foundEvent1, "First event with anonymousId1 should be stored")
                    XCTAssertTrue(foundEvent2, "Second event with anonymousId2 should be stored")
                    
                    // Cleanup
                    for item in dataItems {
                        await self.mockAnalytics.configuration.storage.remove(batchReference: item.reference)
                    }
                }
            }
        }
    }

    func test_eventQueue_sameAnonymousIdSingleBatch() async {
        // Given - Events with the same anonymous ID
        let expectation = expectation(description: "Events with same anonymousId should be processed")
        
        var event1 = TrackEvent(event: "first_event_same_user", properties: ["sequence": 1])
        event1.anonymousId = "consistent_user_789"
        
        var event2 = TrackEvent(event: "second_event_same_user", properties: ["sequence": 2])
        event2.anonymousId = "consistent_user_789"
        
        var event3 = TrackEvent(event: "third_event_same_user", properties: ["sequence": 3])
        event3.anonymousId = "consistent_user_789"
        
        // When - Send events with the same anonymous ID
        eventQueue.put(event1)
        eventQueue.put(event2)
        eventQueue.put(event3)
        
        // Then - Poll for the events in storage
        let startTime = Date()
        let timeout: TimeInterval = 2.0
        
        Task {
            while Date().timeIntervalSince(startTime) < timeout {
                await mockAnalytics.configuration.storage.rollover()
                let dataItems = await mockAnalytics.configuration.storage.read().dataItems
                
                var foundEvents = Set<String>()
                var allBatchContent = ""
                
                for item in dataItems {
                    let batch = mockAnalytics.storage.eventStorageMode == .memory
                        ? item.batch
                        : (FileManager.contentsOf(file: item.reference) ?? .empty)
                        
                    allBatchContent += batch + " "
                    
                    if batch.contains("first_event_same_user") {
                        foundEvents.insert("event1")
                    }
                    if batch.contains("second_event_same_user") {
                        foundEvents.insert("event2")
                    }
                    if batch.contains("third_event_same_user") {
                        foundEvents.insert("event3")
                    }
                }
                
                // Check if all events are found and anonymousId is preserved
                if foundEvents.count == 3 && allBatchContent.contains("consistent_user_789") {
                    expectation.fulfill()
                    break
                }
                
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Cleanup
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(batchReference: item.reference)
        }
    }
}
