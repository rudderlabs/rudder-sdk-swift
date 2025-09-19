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
        // Given - Events with different anonymous IDs
        let expectation = expectation(description: "Storage should rollover when anonymousId changes")

        var event1 = TrackEvent(event: "event_1", properties: ["test": "value1"])
        event1.anonymousId = "anonymousId1"

        var event2 = TrackEvent(event: "event_2", properties: ["test": "value2"])
        event2.anonymousId = "anonymousId2"

        // Track initial batch count
        let initialDataItems = await mockAnalytics.configuration.storage.read().dataItems
        let initialBatchCount = initialDataItems.count

        // When - Send events with different anonymous IDs
        eventQueue.put(event1)
        eventQueue.put(event2)
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Force rollover to finalize the batch
        await mockAnalytics.configuration.storage.rollover()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then - Check that rollovers occurred
        let finalDataItems = await mockAnalytics.configuration.storage.read().dataItems
        let finalBatchCount = finalDataItems.count

        // We should have at least 2 batches (one for anonymousId1, one for anonymousId2)
        XCTAssertEqual(finalBatchCount - initialBatchCount, 2, "Storage should have rolled over when anonymousId changed")

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)

        // Cleanup
        for item in finalDataItems {
            await mockAnalytics.configuration.storage.remove(batchReference: item.reference)
        }
    }

    func test_eventQueue_sameAnonymousIdSingleBatch() async {
        // Given - Multiple events with the same anonymous ID
        let expectation = expectation(description: "Events with same anonymousId should create only one batch")

        var event1 = TrackEvent(event: "event_1", properties: ["test": "value1"])
        event1.anonymousId = "consistentAnonymousId"

        var event2 = TrackEvent(event: "event_2", properties: ["test": "value2"])
        event2.anonymousId = "consistentAnonymousId"

        // Track initial batch count
        let initialDataItems = await mockAnalytics.configuration.storage.read().dataItems
        let initialBatchCount = initialDataItems.count

        // When - Send events with same anonymous ID
        eventQueue.put(event1)
        eventQueue.put(event2)
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Force rollover to finalize the batch
        await mockAnalytics.configuration.storage.rollover()
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then - Check that only one additional batch was created
        let finalDataItems = await mockAnalytics.configuration.storage.read().dataItems
        let finalBatchCount = finalDataItems.count

        // Should have exactly one new batch since all events have the same anonymousId
        XCTAssertEqual(finalBatchCount - initialBatchCount, 1, "Events with same anonymousId should create only one batch")

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 2.0)

        // Cleanup
        for item in finalDataItems {
            await mockAnalytics.configuration.storage.remove(batchReference: item.reference)
        }
    }
}
