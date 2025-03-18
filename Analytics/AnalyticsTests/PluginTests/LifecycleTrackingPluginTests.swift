//
//  LifecycleTrackingPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import UIKit
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
        guard let eventName = await readCurrentEventName() else { XCTFail("No event recorded"); return }
        // TODO: Will be fixed in next PR...
        XCTAssert(eventName == LifecycleEvent.applicationInstalled.rawValue)
    }
    
    func test_application_opened_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("When the app become active")
        plugin.onBecomeActive()
        
        print("Then the plugin should track application opened event")
        guard let eventName = await readCurrentEventName() else { XCTFail("No event recorded"); return }
        XCTAssert(eventName == LifecycleEvent.applicationOpened.rawValue)
    }
    
    func test_application_backgrounded_event() async {
        print("Given an analytics configuration allows lifecycle tracking")
        analyticsMock?.configuration.trackApplicationLifecycleEvents = true
        guard let analyticsMock else { XCTFail("No disk client"); return }
        plugin.setup(analytics: analyticsMock)
        
        print("When the app become active")
        plugin.onBackground()
        
        print("Then the plugin should track application backgrounded event")
        guard let eventName = await readCurrentEventName() else { XCTFail("No event recorded"); return }
        XCTAssert(eventName == LifecycleEvent.applicationBackgrounded.rawValue)
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
        guard let eventName = await readCurrentEventName() else { XCTFail("No event recorded"); return }
        // TODO: Will be fixed in next PR...
        XCTAssert(eventName == LifecycleEvent.applicationUpdated.rawValue)
    }
    
    private func readCurrentEventName() async -> String? {
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard let analyticsMock else { return nil }
        await analyticsMock.configuration.storage.rollover()
        let dataItems = await analyticsMock.configuration.storage.read().dataItems
        let batch = dataItems.first?.batch ?? ""
        guard let batchDict = batch.toDictionary?["batch"] as? [[String: Any]],
                let eventDict = batchDict.last,
                let eventName = eventDict["event"] as? String else { return nil }
        
        for item in dataItems {
            await analyticsMock.configuration.storage.remove(eventReference: item.reference)
        }
        return eventName
    }
}
