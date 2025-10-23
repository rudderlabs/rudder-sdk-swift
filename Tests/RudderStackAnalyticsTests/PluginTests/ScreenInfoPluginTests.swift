//
//  ScreenInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("ScreenInfoPlugin Tests")
class ScreenInfoPluginTests {
    var screenInfoPlugin: ScreenInfoPlugin
    
    init() {
        self.screenInfoPlugin = ScreenInfoPlugin()
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
        screenInfoPlugin.setup(analytics: analytics)
        
        let result = screenInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["screen"] != nil)
        guard let screenInfo = context["screen"] as? [String: Any] else {
            Issue.record("screen info not found")
            return
        }
        
        #expect(screenInfo["width"] != nil)
        #expect(screenInfo["height"] != nil)
        #expect(screenInfo["density"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        screenInfoPlugin.setup(analytics: analytics)
        
        #expect(screenInfoPlugin.analytics != nil)
        #expect(screenInfoPlugin.pluginType == .preProcess)
    }
}
