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
        eventQueue?.stop()
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
        
        // Use a background task to poll storage without sleep
        Task {
            while true {
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
                await Task.yield() // give control back to the executor
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Cleanup
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(eventReference: item.reference)
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
        Task {
            while true {
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
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Cleanup
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(eventReference: item.reference)
        }
    }
    
    func test_eventQueue_stopPreventsNewEvents() async {
        // Given
        let expectation = expectation(description: "Stop should prevent new events")
        
        // When
        eventQueue.stop()
        
        // Try to add event after stop
        let event = TrackEvent(event: "should_not_process", properties: ["test": "value"])
        eventQueue.put(event)
        
        // Then - Verify no new events are processed
        Task {
            while true {
                await mockAnalytics.configuration.storage.rollover()
                let dataItems = await mockAnalytics.configuration.storage.read().dataItems
                
                // If any items got processed after stop, fail
                var processed = false
                for item in dataItems {
                    let batch = mockAnalytics.storage.eventStorageMode == .memory
                        ? item.batch
                        : (FileManager.contentsOf(file: item.reference) ?? .empty)
                    
                    if batch.contains("should_not_process") {
                        XCTFail("Event was processed even after stop() was called")
                        processed = true
                        break
                    }
                }
                
                // If queue is stopped and nothing processed → success
                if !processed {
                    expectation.fulfill()
                    break
                }
                
                await Task.yield()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Cleanup any existing events
        let dataItems = await mockAnalytics.configuration.storage.read().dataItems
        for item in dataItems {
            await mockAnalytics.configuration.storage.remove(eventReference: item.reference)
        }
    }
}
