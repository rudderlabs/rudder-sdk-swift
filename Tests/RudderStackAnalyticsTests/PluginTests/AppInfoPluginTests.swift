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
    
    @Test("when intercepting TrackEvent, then adds app context information")
    func testAppInfoPlugin_InterceptTrackEvent() {
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        
        let result = appInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        #expect(context["app"] != nil)
    }
    
    @Test("when intercepting IdentifyEvent, then adds app context information")
    func testAppInfoPlugin_InterceptIdentifyEvent() {
        let identifyEvent = SwiftTestMockProvider.mockIdentifyEvent
        
        let result = appInfoPlugin.intercept(event: identifyEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        #expect(context["app"] != nil)
    }
    
    @Test("given AppInfoPlugin, when setup is called, then analytics reference is stored")
    func testAppInfoPlugin_Setup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        appInfoPlugin.setup(analytics: analytics)
        
        #expect(appInfoPlugin.analytics != nil)
        #expect(appInfoPlugin.pluginType == .preProcess)
    }
}
