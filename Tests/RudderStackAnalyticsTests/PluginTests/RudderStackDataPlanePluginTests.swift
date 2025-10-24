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
    
    init() {
        self.plugin = RudderStackDataPlanePlugin()
    }
    
    @Test("when event is processed, then returns the same event", arguments: [
            (EventType.track, SwiftTestMockProvider.mockTrackEvent as any Event, TrackEvent.self as Any.Type),
            (EventType.identify, SwiftTestMockProvider.mockIdentifyEvent as any Event, IdentifyEvent.self as Any.Type),
            (EventType.screen, SwiftTestMockProvider.mockScreenEvent as any Event, ScreenEvent.self as Any.Type),
            (EventType.group, SwiftTestMockProvider.mockGroupEvent as any Event, GroupEvent.self as Any.Type),
            (EventType.alias, SwiftTestMockProvider.mockAliasEvent as any Event, AliasEvent.self as Any.Type)
        ])
    func testRudderStackDataPlanePlugin_ProcessEvent(_ eventType: EventType, _ event: any Event, _ expectedType: Any.Type) {
        let plugin = RudderStackDataPlanePlugin()
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        plugin.setup(analytics: analytics)
        
        let result: (any Event)?
        switch eventType {
        case .track:
            result = plugin.track(payload: event as! TrackEvent)
        case .identify:
            result = plugin.identify(payload: event as! IdentifyEvent)
        case .screen:
            result = plugin.screen(payload: event as! ScreenEvent)
        case .group:
            result = plugin.group(payload: event as! GroupEvent)
        case .alias:
            result = plugin.alias(payload: event as! AliasEvent)
        }
        
        #expect(result != nil, "Expected non-nil result for \(eventType.rawValue)")
        #expect(type(of: result!) == expectedType, "Expected result to be \(expectedType)")
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        plugin.setup(analytics: analytics)
        
        #expect(plugin.analytics != nil)
        #expect(plugin.pluginType == .terminal)
    }
}
