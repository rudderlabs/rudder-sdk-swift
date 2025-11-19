//
//  SessionTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("SessionTrackingPlugin Tests")
class SessionTrackingPluginTests {
    var sessionTrackingPlugin: SessionTrackingPlugin
    
    init() {
        self.sessionTrackingPlugin = SessionTrackingPlugin()
    }
    
    @Test("given SessionTrackingPlugin with active session, when intercepting event, then adds session information", arguments:[
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func test_pluginInterceptWithActiveSession(_ event: Event) {
        let sessionConfig = MockProvider.mockSessionConfiguration
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        
        // Start a session
        analytics.startSession()
        
        let result = sessionTrackingPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["sessionId"] != nil)
    }
    
    @Test("given SessionTrackingPlugin without active session, when intercepting event, then context is empty")
    func testSessionTrackingPlugin_WithoutActiveSession() {
        let sessionConfig = MockProvider.mockManualSessionConfiguration
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        
        let trackEvent = MockProvider.mockTrackEvent
        let result = sessionTrackingPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        // When no session is active, the context should be minimal
        #expect(context["sessionId"] == nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        sessionTrackingPlugin.setup(analytics: analytics)
        
        #expect(sessionTrackingPlugin.analytics != nil)
        #expect(sessionTrackingPlugin.pluginType == .preProcess)
    }
}
