//
//  AppInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("AppInfoPlugin Tests")
class AppInfoPluginTests {
    var appInfoPlugin: AppInfoPlugin
    
    init() {
        self.appInfoPlugin = AppInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds app context information", arguments:[
        SwiftTestMockProvider.mockTrackEvent as Event,
        SwiftTestMockProvider.mockScreenEvent as Event,
        SwiftTestMockProvider.mockIdentifyEvent as Event,
        SwiftTestMockProvider.mockGroupEvent as Event,
        SwiftTestMockProvider.mockAliasEvent as Event
    ])
    func test_pluginIntercept(_ event: Event) {
        let result = appInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        #expect(context["app"] != nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        appInfoPlugin.setup(analytics: analytics)
        
        #expect(appInfoPlugin.analytics != nil)
        #expect(appInfoPlugin.pluginType == .preProcess)
    }
}
