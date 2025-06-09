//
//  LifecycleTrackingPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import Foundation
import XCTest
@testable import Analytics

final class LifecycleTrackingPluginTests: XCTestCase {
    var analyticsMock: AnalyticsClient?
    var plugin: LifecycleTrackingPlugin!
    
    override func setUp() {
        super.setUp()
        analyticsMock = MockProvider.clientWithMemoryStorage
        plugin = LifecycleTrackingPlugin()
    }
    
    override func tearDown() {
        analyticsMock = nil
        plugin = nil
        super.tearDown()
    }
    
    func test_application_installed_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        
        print("When the plugin setup with the given analytics configuration")
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("Then the app version should be initialized")
        XCTAssertNotNil(plugin.appVersion)
        
        print("Then the plugin should track installation event")
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        
        XCTAssert(eventNames.first == LifecycleEvent.applicationInstalled.rawValue && eventNames.last == LifecycleEvent.applicationOpened.rawValue)
    }
    
    func test_application_opened_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("When the app become active")
        plugin.onBecomeActive()
        
        print("Then the plugin should track application opened event")
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        
        XCTAssert(eventNames.last == LifecycleEvent.applicationOpened.rawValue)
    }
    
    func test_application_backgrounded_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("When the app moves to background")
        plugin.onBackground()
        
        print("Then the plugin should track application backgrounded event")
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        XCTAssert(eventNames.last == LifecycleEvent.applicationBackgrounded.rawValue)
    }
    
    func test_application_updated_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("When the app got update")
        plugin.appVersion = AppVersion(
            currentVersionName: "2.0",
            currentBuild: 20,
            previousVersionName: "1.0",
            previousBuild: 10
        )
        plugin.trackAppInstallAndUpdateEvents()
        
        print("Then the plugin should track application updated event")
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        
        XCTAssert(eventNames.contains(LifecycleEvent.applicationUpdated.rawValue))
    }
    
    func test_trackAppInstallAndUpdateEvents_does_not_fire_opened_event_on_watchOS_macOS() async {
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        // Simulate app install/update events
        plugin.trackAppInstallAndUpdateEvents()
        
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        
        #if os(watchOS) || os(macOS)
        // On watchOS and macOS, Application Opened should NOT be tracked automatically
        XCTAssertFalse(eventNames.contains(LifecycleEvent.applicationOpened.rawValue),
                      "Application Opened event should NOT be tracked automatically on watchOS and macOS to prevent duplicate tracking")
        #endif
    }
    
    private func fetchTrackedEventNames() async -> [String] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard let analyticsMock else { return [] }

        await analyticsMock.configuration.storage.rollover()
        
        let dataItems = await analyticsMock.configuration.storage.read().dataItems
        let batchData = dataItems.first?.batch.toDictionary?["batch"] as? [[String: Any]] ?? []
        let eventNames = batchData.compactMap { $0["event"] as? String }
        
        for item in dataItems {
            await analyticsMock.configuration.storage.remove(eventReference: item.reference)
        }

        return eventNames
    }
}
