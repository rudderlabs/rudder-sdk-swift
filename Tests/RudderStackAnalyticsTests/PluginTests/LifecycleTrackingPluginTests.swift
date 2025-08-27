//
//  LifecycleTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import Foundation
import XCTest
@testable import RudderStackAnalytics

final class LifecycleTrackingPluginTests: XCTestCase {
    var analyticsMock: Analytics?
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

        XCTAssert(eventNames.first == LifecycleEvent.applicationInstalled.rawValue)
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
        
        print("And given previous version info is stored")
        analyticsMock.storage.write(value: "1.0", key: Constants.storageKeys.appVersion)
        analyticsMock.storage.write(value: 10, key: Constants.storageKeys.appBuild)
        
        print("When the plugin setup with updated app version")
        plugin.setup(analytics: analyticsMock)
        
        print("Then the plugin should track application updated event")
        let eventNames = await fetchTrackedEventNames()
        guard !eventNames.isEmpty else { XCTFail("No events recorded"); return }
        
        XCTAssert(eventNames.contains(LifecycleEvent.applicationUpdated.rawValue))
    }
    
    private func fetchTrackedEventNames() async -> [String] {
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard let analyticsMock else { return [] }

        await analyticsMock.configuration.storage.rollover()
        
        let dataItems = await analyticsMock.configuration.storage.read().dataItems
        
        guard let firstDataItem = dataItems.first else {
            XCTFail("No data items to read"); return []
        }
        
        let batch = analyticsMock.storage.eventStorageMode == .memory ? firstDataItem.batch : (FileManager.contentsOf(file: firstDataItem.reference) ?? "")
        let batchData = batch.toDictionary?["batch"] as? [[String: Any]] ?? []
        let eventNames = batchData.compactMap { $0["event"] as? String }
        
        for item in dataItems {
            await analyticsMock.configuration.storage.remove(batchReference: item.reference)
        }

        return eventNames
    }
}
