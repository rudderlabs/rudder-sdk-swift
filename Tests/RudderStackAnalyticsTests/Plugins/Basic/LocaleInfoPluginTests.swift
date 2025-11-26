//
//  LocaleInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("LocaleInfoPlugin Tests")
class LocaleInfoPluginTests {
    var localeInfoPlugin: LocaleInfoPlugin
    
    init() {
        self.localeInfoPlugin = LocaleInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds locale context information", arguments:[
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func testPluginIntercept(_ event: Event) {
        let analytics = MockProvider.createMockAnalytics()
        localeInfoPlugin.setup(analytics: analytics)
        
        let result = localeInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["locale"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        localeInfoPlugin.setup(analytics: analytics)
        
        #expect(localeInfoPlugin.analytics != nil)
        #expect(localeInfoPlugin.pluginType == .preProcess)
    }
}
