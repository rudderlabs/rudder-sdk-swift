//
//  LifecycleTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("LifecycleTrackingPlugin Tests")
struct LifecycleTrackingPluginTests {
    private static let sentinelEvent = "sentinel"
    private let mockStorage = MockStorage()
    private let eventCapture = MockEventCapturePlugin(type: .onProcess)
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let lifecycleTrackingPlugin = LifecycleTrackingPlugin()
        
        lifecycleTrackingPlugin.setup(analytics: MockProvider.createMockAnalytics())
        
        #expect(lifecycleTrackingPlugin.analytics != nil)
        #expect(lifecycleTrackingPlugin.pluginType == .utility)
    }
    
    // MARK: - Background Start Tests
    
    @Test("given an app that starts in the background, when the SDK starts, then it sends no lifecycle event and writes no app-version marker")
    func testBackgroundStartSendsNoLifecycleEvent() async {
        let analytics = makeAnalytics()
        
        let eventNames = await trackedEventNames(of: analytics)
        
        #expect(eventNames == [Self.sentinelEvent])
        #expect(storedAppBuild == nil)
    }
    
    @Test("given an app that started in the background, when a background event arrives, then it sends no application backgrounded event")
    func testBackgroundWithoutForegroundSendsNoBackgroundedEvent() async {
        let analytics = makeAnalytics()
        
        analytics.simulateLifecycleEvent(.background)
        
        #expect(await trackedEventNames(of: analytics) == [Self.sentinelEvent])
    }
    
    // MARK: - First Foreground Tests
    
    @Test("given a new install, when the app comes to the foreground for the first time, then application installed and application opened are sent once")
    func testFirstForegroundSendsInstalledAndOpened() async {
        let analytics = makeAnalytics()
        
        analytics.simulateLifecycleEvent(.foreground)
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let events = await trackedEvents(of: analytics)
        #expect(events.map(\.event) == [LifecycleEvent.applicationInstalled.rawValue, LifecycleEvent.applicationOpened.rawValue, Self.sentinelEvent])
        #expect(events[1].properties?.dictionary?.rawDictionary["from_background"] as? Bool == false)
        #expect(storedAppBuild != nil)
    }
    
    @Test("given a stored app version that differs, when the app comes to the foreground for the first time, then application updated is sent")
    func testFirstForegroundSendsUpdated() async {
        mockStorage.write(value: "0.0.1-previous", key: Constants.storageKeys.appVersion)
        mockStorage.write(value: 10, key: Constants.storageKeys.appBuild)
        let analytics = makeAnalytics()
        
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let events = await trackedEvents(of: analytics)
        #expect(events.map(\.event) == [LifecycleEvent.applicationUpdated.rawValue, LifecycleEvent.applicationOpened.rawValue, Self.sentinelEvent])
        let properties = events[0].properties?.dictionary?.rawDictionary
        #expect(properties?["previous_version"] as? String == "0.0.1-previous")
        #expect(properties?["previous_build"] as? Int == 10)
    }
    
    // MARK: - Later Foreground Tests
    
    @Test("given an app in the foreground, when it moves to the background and returns, then application backgrounded and a reopen are sent")
    func testReturnToForegroundSendsBackgroundedAndOpened() async {
        let analytics = makeAnalytics()
        analytics.simulateLifecycleEvent(.becomeActive)
        
        analytics.simulateLifecycleEvent(.background)
        analytics.simulateLifecycleEvent(.foreground)
        analytics.simulateLifecycleEvent(.becomeActive)
        
        let events = await trackedEvents(of: analytics)
        #expect(events.map(\.event) == [
            LifecycleEvent.applicationInstalled.rawValue,
            LifecycleEvent.applicationOpened.rawValue,
            LifecycleEvent.applicationBackgrounded.rawValue,
            LifecycleEvent.applicationOpened.rawValue,
            Self.sentinelEvent
        ])
        #expect(events[3].properties?.dictionary?.rawDictionary["from_background"] as? Bool == true)
    }
    
    // MARK: - Lifecycle Tracking Disabled Tests
    
    @Test("given lifecycle tracking is off, when the SDK starts, then it writes the app-version marker and sends no lifecycle event")
    func testLifecycleTrackingOffWritesMarkerAtSetup() async {
        let analytics = makeAnalytics(trackApplicationLifecycleEvents: false)
        #expect(storedAppBuild != nil)
        
        analytics.simulateLifecycleEvent(.becomeActive)
        analytics.simulateLifecycleEvent(.background)
        
        #expect(await trackedEventNames(of: analytics) == [Self.sentinelEvent])
    }
}

// MARK: - Helpers

extension LifecycleTrackingPluginTests {
    private var storedAppBuild: Int? {
        return mockStorage.read(key: Constants.storageKeys.appBuild)
    }
    
    private func makeAnalytics(trackApplicationLifecycleEvents: Bool = true) -> Analytics {
        let configuration = MockProvider.createMockConfiguration(storage: mockStorage)
        configuration.trackApplicationLifecycleEvents = trackApplicationLifecycleEvents
        let analytics = Analytics(configuration: configuration)
        analytics.add(plugin: eventCapture)
        return analytics
    }
    
    /// Tracks a sentinel event and returns every track event up to it, so the absence of an event is observable.
    private func trackedEvents(of analytics: Analytics) async -> [TrackEvent] {
        analytics.track(name: Self.sentinelEvent)
        
        let timeout: TimeInterval = 2
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            let events = eventCapture.getEventsOfType(TrackEvent.self)
            if events.last?.event == Self.sentinelEvent { return events }
            await Task.yield()
        }
        return eventCapture.getEventsOfType(TrackEvent.self)
    }
    
    private func trackedEventNames(of analytics: Analytics) async -> [String] {
        return await trackedEvents(of: analytics).map(\.event)
    }
}
