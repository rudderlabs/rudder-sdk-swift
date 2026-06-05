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
    func testPluginInterceptWithActiveSession(_ event: Event) {
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
    func testSessionTrackingPluginWithoutActiveSession() {
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
    func testPluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        sessionTrackingPlugin.setup(analytics: analytics)
        
        #expect(sessionTrackingPlugin.analytics != nil)
        #expect(sessionTrackingPlugin.pluginType == .preProcess)
    }

    @Test("given app is backgrounded and updateSessionOnBackgroundEvents is false, when intercepting an automatic session event, then last activity time is not updated")
    func testInterceptDoesNotUpdateActivityTimeForBackgroundEvent() {
        let sessionConfig = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        let sessionHandler = analytics.sessionHandler
        sessionHandler?.onBackground()
        let activityTimeBeforeEvent = sessionHandler?.lastActivityTime

        _ = sessionTrackingPlugin.intercept(event: MockProvider.mockTrackEvent)

        #expect(sessionHandler?.lastActivityTime == activityTimeBeforeEvent)
    }

    @Test("given app is backgrounded and updateSessionOnBackgroundEvents is true, when intercepting an automatic session event, then last activity time is updated")
    func testInterceptUpdatesActivityTimeForBackgroundEventWhenEnabled() {
        let sessionConfig = SessionConfiguration(automaticSessionTracking: true, updateSessionOnBackgroundEvents: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        let sessionHandler = analytics.sessionHandler
        sessionHandler?.onBackground()
        // Reset to a known past value so the update produces a strictly different result
        sessionHandler?.updateSessionLastActivityTime(0)
        let activityTimeBeforeEvent = sessionHandler?.lastActivityTime

        _ = sessionTrackingPlugin.intercept(event: MockProvider.mockTrackEvent)

        #expect(sessionHandler?.lastActivityTime != activityTimeBeforeEvent)
    }

    @Test("given app is in foreground, when intercepting an automatic session event, then last activity time is updated")
    func testInterceptUpdatesActivityTimeForForegroundEvent() {
        let sessionConfig = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        let sessionHandler = analytics.sessionHandler
        sessionHandler?.onForeground()
        let activityTimeBeforeEvent = sessionHandler?.lastActivityTime

        _ = sessionTrackingPlugin.intercept(event: MockProvider.mockTrackEvent)

        #expect(sessionHandler?.lastActivityTime != activityTimeBeforeEvent)
    }
}
