//
//  OSInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("OSInfoPlugin Tests")
class OSInfoPluginTests {
    var osInfoPlugin: OSInfoPlugin
    
    init() {
        self.osInfoPlugin = OSInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds network context information", arguments:[
        SwiftTestMockProvider.mockTrackEvent as Event,
        SwiftTestMockProvider.mockScreenEvent as Event,
        SwiftTestMockProvider.mockIdentifyEvent as Event,
        SwiftTestMockProvider.mockGroupEvent as Event,
        SwiftTestMockProvider.mockAliasEvent as Event
    ])
    func test_pluginIntercept(_ event: Event) {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        osInfoPlugin.setup(analytics: analytics)
        
        let result = osInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["os"] != nil)
        guard let osInfo = context["os"] as? [String: Any] else {
            Issue.record("os info not found")
            return
        }
        
        #expect(osInfo["name"] != nil)
        #expect(osInfo["version"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        osInfoPlugin.setup(analytics: analytics)
        
        #expect(osInfoPlugin.analytics != nil)
        #expect(osInfoPlugin.pluginType == .preProcess)
    }
}
