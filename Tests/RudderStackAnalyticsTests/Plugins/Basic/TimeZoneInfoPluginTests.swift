//
//  TimeZoneInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("TimeZoneInfoPlugin Tests")
class TimeZoneInfoPluginTests {
    var timeZoneInfoPlugin: TimeZoneInfoPlugin
    
    init() {
        self.timeZoneInfoPlugin = TimeZoneInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds timezone context information", arguments: [
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func testPluginIntercept(_ event: Event) {
        let analytics = MockProvider.createMockAnalytics()
        timeZoneInfoPlugin.setup(analytics: analytics)
        
        let result = timeZoneInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["timezone"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        timeZoneInfoPlugin.setup(analytics: analytics)
        
        #expect(timeZoneInfoPlugin.analytics != nil)
        #expect(timeZoneInfoPlugin.pluginType == .preProcess)
    }
}
