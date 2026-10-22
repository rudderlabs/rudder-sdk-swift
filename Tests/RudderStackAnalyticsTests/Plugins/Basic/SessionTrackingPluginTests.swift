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

    @Test("given an event created in the background, when it is intercepted after the app returns to the foreground, then last activity time is not updated")
    func testInterceptKeepsBackgroundCreationStateAfterAppReturnsToForeground() {
        let sessionConfig = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        let sessionHandler = analytics.sessionHandler
        var event = MockProvider.mockTrackEvent
        event.createdInForeground = false
        sessionHandler?.onForeground()
        sessionHandler?.updateSessionLastActivityTime(0)

        _ = sessionTrackingPlugin.intercept(event: event)

        #expect(sessionHandler?.lastActivityTime == 0)
    }

    @Test("given an event created in the foreground, when it is intercepted after the app moves to the background, then last activity time is updated")
    func testInterceptKeepsForegroundCreationStateAfterAppMovesToBackground() {
        let sessionConfig = SessionConfiguration(automaticSessionTracking: true)
        let analytics = MockProvider.createMockAnalytics(sessionConfig: sessionConfig)
        sessionTrackingPlugin.setup(analytics: analytics)
        let sessionHandler = analytics.sessionHandler
        var event = MockProvider.mockTrackEvent
        event.createdInForeground = true
        sessionHandler?.onBackground()
        sessionHandler?.updateSessionLastActivityTime(0)

        _ = sessionTrackingPlugin.intercept(event: event)

        #expect(sessionHandler?.lastActivityTime != 0)
    }

    @Test("given the app state, when an event is tracked, then the event records that state at creation", arguments: [true, false])
    func testTrackRecordsForegroundStateAtCreation(isInForeground: Bool) async {
        let analytics = MockProvider.createMockAnalytics(sessionConfig: SessionConfiguration(automaticSessionTracking: true))
        let recorder = CreationStateRecordingPlugin(eventName: "creation_state_probe")
        analytics.add(plugin: recorder)
        if !isInForeground {
            analytics.sessionHandler?.onBackground()
        }

        analytics.track(name: "creation_state_probe")

        #expect(await recorder.recordedState() == isInForeground)
    }
}

// MARK: - CreationStateRecordingPlugin
/// Records the creation state of one named event as it passes through the plugin chain.
private final class CreationStateRecordingPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?

    @Synchronized private var createdInForeground: Bool?
    private let eventName: String

    init(eventName: String) {
        self.eventName = eventName
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: any Event) -> (any Event)? {
        if let track = event as? TrackEvent, track.event == eventName {
            createdInForeground = track.createdInForeground
        }
        return event
    }

    /// Bounded, so a test whose event never arrives fails on its expectation instead of hanging.
    func recordedState() async -> Bool? {
        for _ in 0..<200 where createdInForeground == nil {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return createdInForeground
    }
}
