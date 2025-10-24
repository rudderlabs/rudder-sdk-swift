//
//  EventQueueTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 23/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("EventQueue Tests")
@MainActor
class EventQueueTests {
    var analytics: Analytics
    var mockStorage: MockStorage
    var eventQueue: EventQueue
    
    init() {
        mockStorage = MockStorage()
        let config = SwiftTestMockProvider.createMockConfiguration(storage: mockStorage)
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.flushPolicies = []
        
        analytics = Analytics(configuration: config)
        analytics.isAnalyticsActive = true
        
        eventQueue = EventQueue(analytics: analytics)
    }
    
    deinit {
        // Use unstructured task to avoid capture issues
        let storage = mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    // MARK: - Event Processing Tests
    
    @Test("when putting single event, then event is processed and stored")
    func testPutSingleEvent() async {
        let event = TrackEvent(event: "test_event", properties: ["key": "value"])
        eventQueue.put(event)
        
        await mockStorage.waitForEvents()
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count > 0)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("test_event"))
        #expect(batchContent.contains("key") && batchContent.contains("value"))
    }

    @Test("when putting multiple events, then all events are processed")
    func testPutMultipleEvents() async {
        let events = [
            TrackEvent(event: "event_1", properties: ["index": 1]),
            TrackEvent(event: "event_2", properties: ["index": 2]),
            TrackEvent(event: "event_3", properties: ["index": 3])
        ]
        
        for event in events {
            eventQueue.put(event)
        }
        
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 3)
        #expect(mockStorage.currentBatchEventCount == 3)
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count > 0)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("event_1"))
        #expect(batchContent.contains("event_2"))
        #expect(batchContent.contains("event_3"))
    }

    @Test("given empty storage, when adding events one by one, then current batch counter accurately reflects event accumulation")
    func testCurrentBatchEventCounter() async {
        guard mockStorage.currentBatchEventCount == 0, mockStorage.totalEventCount == 0 else {
            Issue.record("Storage is not empty")
            return
        }
        
        // Adding events one by one
        eventQueue.put(TrackEvent(event: "counter_test_1", properties: ["step": 1]))
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 1)
        
        // Counter should reflect single event
        #expect(mockStorage.currentBatchEventCount == 1)
        #expect(mockStorage.totalEventCount == 1)
        
        // Adding second event
        eventQueue.put(TrackEvent(event: "counter_test_2", properties: ["step": 2]))
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 2)
        
        // Counter should reflect both events
        #expect(mockStorage.currentBatchEventCount == 2)
        #expect(mockStorage.totalEventCount == 2)
        
        // Triggering rollover
        await mockStorage.rollover()
        
        // Current batch counter should reset, but total should remain
        #expect(mockStorage.currentBatchEventCount == 0)
        #expect(mockStorage.totalEventCount == 2)
        
        #expect(mockStorage.batchCount == 1)
        
        let batchContent = await mockStorage.read().dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("counter_test_1"))
        #expect(batchContent.contains("counter_test_2"))
    }
    
    @Test("when calling flush, then events are flushed immediately")
    func testFlushEvents() async {
        let event = TrackEvent(event: "flush_test_event", properties: ["flush": true])
        eventQueue.put(event)
        
        await mockStorage.waitForCurrentBatchEvents()
        
        eventQueue.flush()
        
        await mockStorage.waitForEventsContaining("flush_test_event")
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count > 0)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("flush_test_event"))
    }
    
    @Test("when EventQueue added with different event types, then all event types are handled")
    func testDifferentEventTypes() async {
        let trackEvent = TrackEvent(event: "track_test", properties: ["type": "track"])
        let identifyEvent = IdentifyEvent(userIdentity: UserIdentity(userId: "test_user_id", traits: ["name": "Test User"]))
        let screenEvent = ScreenEvent(screenName: "test_screen", category: "screen", properties: ["type": "screen"])
        
        eventQueue.put(trackEvent)
        eventQueue.put(identifyEvent)
        eventQueue.put(screenEvent)
        
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 3)
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count > 0)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("track_test"))
        #expect(batchContent.contains("identify"))
        #expect(batchContent.contains("test_screen"))
    }
    
    @Test("given EventQueue with anonymous ID change, when processing events, then triggers rollover with both IDs")
    func testAnonymousIdChangeTriggersRollover() async {
        let event1 = TrackEvent(event: "before_change", properties: ["timestamp": "\(Date().timeIntervalSince1970)"])
        let event2 = TrackEvent(event: "after_change", properties: ["timestamp": "\(Date().timeIntervalSince1970)"])
        
        eventQueue.put(event1)
        eventQueue.flush() // Ensure first event is processed
        
        await mockStorage.waitForEventsContaining("before_change")
        
        // Change anonymous ID by resetting only the anonymous ID
        let resetOptions = ResetOptions(entries: ResetEntries(
            anonymousId: true,
            userId: false,
            traits: false,
            session: false
        ))
        analytics.reset(options: resetOptions)
        
        eventQueue.put(event2)
        eventQueue.flush() // Ensure second event is processed
        
        await mockStorage.waitForEventsContaining("after_change")
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count == 2)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("before_change") && batchContent.contains("after_change"))
    }
}
