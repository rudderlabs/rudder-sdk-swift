//
//  SessionTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("SessionTrackingPlugin Tests")
struct SessionTrackingPluginTests {
    private static let storedSessionId: UInt64 = 1234567890
    private let sessionTrackingPlugin = SessionTrackingPlugin()
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        sessionTrackingPlugin.setup(analytics: MockProvider.createMockAnalytics())
        
        #expect(sessionTrackingPlugin.analytics != nil)
        #expect(sessionTrackingPlugin.pluginType == .preProcess)
    }
    
    // MARK: - Foreground Event Tests
    
    @Test("given an automatic session, when intercepting a foreground event, then adds session information", arguments: [
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func testForegroundEventCarriesSession(_ event: Event) {
        let analytics = makeAnalytics()
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let context = interceptedContext(of: event)
        
        #expect(carriedSessionId(in: context) == analytics.sessionHandler?.sessionId)
    }
    
    @Test("given a new session, when intercepting events, then only the first event that carries the session has sessionStart")
    func testSessionStartIsOnTheFirstEventOnly() {
        makeAnalytics().simulateLifecycleEvent(.becomeActive)
        
        let firstContext = interceptedContext(of: MockProvider.mockTrackEvent)
        let secondContext = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(firstContext["sessionStart"] as? Bool == true)
        #expect(secondContext["sessionId"] != nil)
        #expect(secondContext["sessionStart"] == nil)
    }
    
    @Test("given an automatic session, when intercepting a foreground event, then last activity time is updated")
    func testForegroundEventExtendsSession() {
        let analytics = makeAnalytics()
        analytics.simulateLifecycleEvent(.becomeActive)
        analytics.sessionHandler?.updateSessionLastActivityTime(1)
        
        _ = sessionTrackingPlugin.intercept(event: MockProvider.mockTrackEvent)
        
        #expect(analytics.sessionHandler?.lastActivityTime != 1)
    }
    
    @Test("given no session, when intercepting event, then the event carries no session information")
    func testEventWithoutSessionCarriesNoSessionInformation() {
        makeAnalytics(SessionConfiguration(automaticSessionTracking: false)).simulateLifecycleEvent(.becomeActive)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(context["sessionId"] == nil)
        #expect(context["sessionStart"] == nil)
    }
    
    // MARK: - Background Event Tests
    
    @Test("given background events are not included, when intercepting a background event, then it carries no session data and does not extend the session")
    func testBackgroundEventCarriesNoSessionWhenNotIncluded() {
        let analytics = makeAnalytics()
        moveToBackgroundWithSession(analytics)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(context["sessionId"] == nil)
        #expect(context["sessionStart"] == nil)
        #expect(analytics.sessionHandler?.lastActivityTime == 1)
        #expect(analytics.sessionHandler?.isSessionStart == true, "The first event that carries the session reports its start.")
    }
    
    @Test("given background events are not included, when intercepting an SDK lifecycle event in the background, then it carries the session and does not extend it", arguments: [
        LifecycleEvent.applicationInstalled, .applicationUpdated, .applicationOpened, .applicationBackgrounded
    ])
    func testBackgroundLifecycleEventCarriesSession(lifecycleEvent: LifecycleEvent) {
        let analytics = makeAnalytics()
        moveToBackgroundWithSession(analytics)
        
        let context = interceptedContext(of: TrackEvent(event: lifecycleEvent.rawValue))
        
        #expect(carriedSessionId(in: context) == analytics.sessionHandler?.sessionId)
        #expect(context["sessionStart"] as? Bool == true)
        #expect(analytics.sessionHandler?.lastActivityTime == 1)
    }
    
    @Test("given background events are included and a live session, when intercepting a background event, then it carries the session and extends it")
    func testBackgroundEventCarriesAndExtendsLiveSessionWhenIncluded() {
        let analytics = makeAnalytics(Self.includingBackgroundEvents)
        moveToBackgroundWithSession(analytics)
        let sessionId = analytics.sessionHandler?.sessionId
        analytics.sessionHandler?.updateSessionLastActivityTime(currentTimeInMillis - 1000)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(carriedSessionId(in: context) == sessionId)
        #expect(analytics.sessionHandler?.lastActivityTime ?? 0 > currentTimeInMillis - 1000)
    }
    
    @Test("given background events are included and no session, when intercepting a background event, then it starts a new session and carries it")
    func testBackgroundEventStartsSessionWhenIncluded() {
        let analytics = makeAnalytics(Self.includingBackgroundEvents)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(context["sessionId"] != nil)
        #expect(carriedSessionId(in: context) == analytics.sessionHandler?.sessionId)
        #expect(context["sessionStart"] as? Bool == true)
    }
    
    @Test("given background events are included and a timed-out session, when intercepting a background event, then it carries a new session")
    func testBackgroundEventReplacesTimedOutSessionWhenIncluded() {
        let storage = MockStorage()
        storage.write(value: String(Self.storedSessionId), key: Constants.storageKeys.sessionId)
        storage.write(value: false, key: Constants.storageKeys.isManualSession)
        storage.write(value: String(currentTimeInMillis - 10000), key: Constants.storageKeys.lastActivityTime)
        makeAnalytics(Self.includingBackgroundEvents, storage: storage)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(context["sessionId"] != nil)
        #expect(carriedSessionId(in: context) != Self.storedSessionId)
        #expect(context["sessionStart"] as? Bool == true)
    }
    
    // MARK: - Manual Session Tests
    
    @Test("given a manual session, when intercepting an event, then it carries the session and the session is not extended", arguments: [true, false])
    func testManualSessionIsOnEveryEventAndIsNotExtended(isInForeground: Bool) {
        let analytics = makeAnalytics()
        if isInForeground {
            analytics.simulateLifecycleEvent(.becomeActive)
        }
        analytics.startSession(sessionId: Self.storedSessionId)
        analytics.sessionHandler?.updateSessionLastActivityTime(1)
        
        let context = interceptedContext(of: MockProvider.mockTrackEvent)
        
        #expect(carriedSessionId(in: context) == Self.storedSessionId)
        #expect(analytics.sessionHandler?.lastActivityTime == 1)
    }
    
    // MARK: - Creation State Tests
    
    @Test("given an event created in the background, when it is intercepted after the app returns to the foreground, then it stays a background event")
    func testInterceptKeepsBackgroundCreationStateAfterAppReturnsToForeground() {
        let analytics = makeAnalytics()
        moveToBackgroundWithSession(analytics)
        var event = MockProvider.mockTrackEvent
        event.createdInForeground = false
        analytics.simulateLifecycleEvent(.foreground)
        let lastActivityTime = currentTimeInMillis - 1000
        analytics.sessionHandler?.updateSessionLastActivityTime(lastActivityTime)
        
        let context = interceptedContext(of: event)
        
        #expect(context["sessionId"] == nil)
        #expect(analytics.sessionHandler?.lastActivityTime == lastActivityTime)
    }
    
    @Test("given an event created in the foreground, when it is intercepted after the app moves to the background, then it stays a foreground event")
    func testInterceptKeepsForegroundCreationStateAfterAppMovesToBackground() {
        let analytics = makeAnalytics()
        analytics.simulateLifecycleEvent(.becomeActive)
        var event = MockProvider.mockTrackEvent
        event.createdInForeground = true
        analytics.simulateLifecycleEvent(.background)
        analytics.sessionHandler?.updateSessionLastActivityTime(1)
        
        let context = interceptedContext(of: event)
        
        #expect(carriedSessionId(in: context) == analytics.sessionHandler?.sessionId)
        #expect(analytics.sessionHandler?.lastActivityTime != 1)
    }
    
    @Test("given the app state, when an event is tracked, then the event records that state at creation", arguments: [true, false])
    func testTrackRecordsForegroundStateAtCreation(isInForeground: Bool) async {
        let analytics = makeAnalytics()
        let recorder = CreationStateRecordingPlugin(eventName: "creation_state_probe")
        analytics.add(plugin: recorder)
        analytics.simulateLifecycleEvent(isInForeground ? .becomeActive : .background)

        analytics.track(name: "creation_state_probe")

        #expect(await recorder.recordedState() == isInForeground)
    }
}

// MARK: - Helpers

extension SessionTrackingPluginTests {
    private static var includingBackgroundEvents: SessionConfiguration {
        return SessionConfiguration(automaticSessionTracking: true, sessionTimeoutInMillis: 5000, includeBackgroundEventsInSession: true)
    }
    
    private var currentTimeInMillis: UInt64 {
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }
    
    @discardableResult
    private func makeAnalytics(
        _ configuration: SessionConfiguration = SessionConfiguration(automaticSessionTracking: true),
        storage: MockStorage = MockStorage()
    ) -> Analytics {
        let analytics = MockProvider.createMockAnalytics(storage: storage, sessionConfig: configuration, trackApplicationLifecycleEvents: false)
        sessionTrackingPlugin.setup(analytics: analytics)
        return analytics
    }
    
    /// Leaves an app in the background with a session whose last activity time is 1, so a change is visible.
    private func moveToBackgroundWithSession(_ analytics: Analytics) {
        analytics.simulateLifecycleEvent(.becomeActive)
        analytics.simulateLifecycleEvent(.background)
        analytics.sessionHandler?.updateSessionLastActivityTime(1)
    }
    
    private func carriedSessionId(in context: [String: Any]) -> UInt64? {
        return (context["sessionId"] as? NSNumber)?.uint64Value
    }
    
    private func interceptedContext(of event: Event) -> [String: Any] {
        return sessionTrackingPlugin.intercept(event: event)?.context?.rawDictionary ?? [:]
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
