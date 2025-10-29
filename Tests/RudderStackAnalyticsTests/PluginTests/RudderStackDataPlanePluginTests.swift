//
//  RudderStackDataPlanePluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 24/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("RudderStackDataPlanePlugin Tests")
class RudderStackDataPlanePluginTests {
    var plugin: RudderStackDataPlanePlugin
    var analytics: Analytics
    var mockStorage: MockStorage
    
    init() {
        self.mockStorage = MockStorage()
        
        let configuration = SwiftTestMockProvider.createMockConfiguration(storage: mockStorage)
        configuration.flushPolicies = []
        configuration.trackApplicationLifecycleEvents = false
        
        self.analytics = Analytics(configuration: configuration)
        self.analytics.isAnalyticsActive = true
        
        self.plugin = RudderStackDataPlanePlugin()
        plugin.setup(analytics: analytics)
    }
    
    deinit {
        let storage = self.mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    @Test("when event methods are called, then events are queued for processing", arguments: [
            (EventType.track, SwiftTestMockProvider.mockTrackEvent as any Event),
            (EventType.identify, SwiftTestMockProvider.mockIdentifyEvent as any Event),
            (EventType.screen, SwiftTestMockProvider.mockScreenEvent as any Event),
            (EventType.group, SwiftTestMockProvider.mockGroupEvent as any Event),
            (EventType.alias, SwiftTestMockProvider.mockAliasEvent as any Event)
        ])
    func testProcessEvent(_ eventType: EventType, _ event: any Event) async {
        switch eventType {
        case .track:
            plugin.track(payload: event as! TrackEvent)
        case .identify:
            plugin.identify(payload: event as! IdentifyEvent)
        case .screen:
            plugin.screen(payload: event as! ScreenEvent)
        case .group:
            plugin.group(payload: event as! GroupEvent)
        case .alias:
            plugin.alias(payload: event as! AliasEvent)
        }
        
        await mockStorage.waitForEvents()
        
        #expect(mockStorage.batchCount > 0, "Events should be processed and stored")
    }
    
    @Test("when calling flush, then batch will be rollovered and events flushed immediately")
    func testFlushEvents() async {
        let event = TrackEvent(event: "flush_test_event", properties: ["flush": true])
        plugin.track(payload: event)
        
        await mockStorage.waitForEvents()
        #expect(mockStorage.totalEventCount == 1, "Events should be processed and stored")
        
        plugin.flush()
        
        await runAfter(0.1) {
            let result = await self.mockStorage.read()
            #expect(result.dataItems.count == 1)
        }
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let localAnalytics = SwiftTestMockProvider.createMockAnalytics()
        
        plugin.setup(analytics: localAnalytics)
        
        #expect(plugin.analytics != nil)
        #expect(plugin.pluginType == .terminal)
    }
}
