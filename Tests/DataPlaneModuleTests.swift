//
//  DataPlaneModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 09/10/24.
//

import XCTest
@testable import RudderStackAnalytics

// MARK: - DataPlaneModuleTests
final class DataPlaneModuleTests: XCTestCase {
    
    var dpPlugin: RudderStackDataPlanePlugin?
    var analytics_disk: AnalyticsClient?
    var analytics_memory: AnalyticsClient?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.dpPlugin = RudderStackDataPlanePlugin()
        self.analytics_disk = MockProvider.clientWithDiskStorage
        self.analytics_memory = MockProvider.clientWithMemoryStorage
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        self.dpPlugin = nil
        self.analytics_disk = nil
        self.analytics_memory = nil
    }
    
    func test_dataPlaneModule_init() {
        guard let analytics = self.analytics_memory else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        XCTAssertNotNil(self.dpPlugin)
    }
}

// MARK: - Memory Store
extension DataPlaneModuleTests {
    
    func test_trackEvent_memory() async {
        guard let analytics = self.analytics_memory else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = TrackEvent(event: "test_track_event")
        _ = self.dpPlugin?.track(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
    
    func test_screenEvent_memory() async {
        guard let analytics = self.analytics_memory else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = ScreenEvent(screenName: "test_screen_event")
        _ = self.dpPlugin?.screen(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
    
    func test_groupEvent_memory() async {
        guard let analytics = self.analytics_memory else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = GroupEvent(groupId: "test_group_event")
        _ = self.dpPlugin?.group(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
}


// MARK: - Disk Store
extension DataPlaneModuleTests {

    func test_trackEvent_disk() async {
        guard let analytics = self.analytics_disk else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = TrackEvent(event: "test_track_event")
        _ = self.dpPlugin?.track(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
    
    func test_screenEvent_disk() async {
        guard let analytics = self.analytics_disk else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = ScreenEvent(screenName: "test_screen_event")
        _ = self.dpPlugin?.screen(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
    
    func test_groupEvent_disk() async {
        guard let analytics = self.analytics_disk else { XCTFail("Analytics not initialized"); return }
        self.dpPlugin?.setup(analytics: analytics)
        
        guard let storage = self.dpPlugin?.analytics?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
        let event = GroupEvent(groupId: "test_group_event")
        _ = self.dpPlugin?.group(payload: event)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        await storage.rollover()
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
}
