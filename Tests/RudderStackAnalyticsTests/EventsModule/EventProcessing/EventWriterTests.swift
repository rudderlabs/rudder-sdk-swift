//
//  EventWriterTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 23/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("EventWriter Tests")
@MainActor
class EventWriterTests {
    var analytics: Analytics
    var mockStorage: MockStorage
    var eventWriter: EventWriter
    var writeChannel: AsyncChannel<ProcessingEvent>
    var uploadChannel: AsyncChannel<String>
    
    init() {
        mockStorage = MockStorage()
        let config = MockProvider.createMockConfiguration(storage: mockStorage)
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.flushPolicies = []
        
        analytics = Analytics(configuration: config)
        analytics.isAnalyticsActive = true
        
        // Create channels
        writeChannel = AsyncChannel<ProcessingEvent>()
        uploadChannel = AsyncChannel<String>()
        
        // Create EventWriter with channels
        eventWriter = EventWriter(analytics: analytics, writeChannel: writeChannel, uploadChannel: uploadChannel)
        eventWriter.start()
    }
    
    deinit {
        eventWriter.stop()
        let storage = mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    // MARK: - Event Processing Tests
    
    @Test("when putting event, then event is stored")
    func testPutEvent() async {
        let trackEvent = TrackEvent(event: "writer_test_event", properties: ["test": "value"])
        eventWriter.put(trackEvent)
        
        await mockStorage.waitForEvents()
        
        let finalResult = await mockStorage.read()
        let allBatches = finalResult.dataItems.map { $0.batch }.joined()
        #expect(allBatches.contains("writer_test_event") || mockStorage.batchCount > 0)
    }
    
    @Test("given EventWriter with events, when flush is triggered, then rollover occurs")
    func testFlushTriggersRollover() async {
        let trackEvent = TrackEvent(event: "rollover_test", properties: ["rollover": true])
        eventWriter.put(trackEvent)
        
        await mockStorage.waitForEvents()
        
        eventWriter.flush()
        await mockStorage.waitForEventsContaining("rollover_test")
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count > 0)
        
        if let firstItem = result.dataItems.first {
            #expect(firstItem.batch.contains("rollover_test"))
        }
    }
    
    @Test("when stopping, then writeChannel is closed")
    func testStopClosesChannel() async {
        eventWriter.stop()
        #expect(writeChannel.isClosed)
    }
    
    @Test("when processing multiple events, then all events are written")
    func testMultipleEventProcessing() async {
        let events = [
            TrackEvent(event: "multi_event_1", properties: ["index": 1]),
            TrackEvent(event: "multi_event_2", properties: ["index": 2]),
            TrackEvent(event: "multi_event_3", properties: ["index": 3])
        ]
                
        for event in events {
            eventWriter.put(event)
        }
        
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 3)
        
        let result = await mockStorage.read()
        #expect(result.dataItems.count == 1)
        
        let batchContent = result.dataItems.map { $0.batch }.joined()
        #expect(batchContent.contains("multi_event_1"))
        #expect(batchContent.contains("multi_event_2"))
        #expect(batchContent.contains("multi_event_3"))
    }
}
