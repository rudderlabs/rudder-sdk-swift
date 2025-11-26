//
//  LifecycleTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("LifecycleTrackingPlugin Tests")
class LifecycleTrackingPluginTests {
    var lifecycleTrackingPlugin: LifecycleTrackingPlugin
    var mockStorage: MockStorage
    var analytics: Analytics
    
    init() {
        self.mockStorage = MockStorage()
        self.analytics = MockProvider.createMockAnalytics(storage: mockStorage)
        self.lifecycleTrackingPlugin = LifecycleTrackingPlugin()
    }
    
    deinit {
        let storage = mockStorage
        Task.detached {
            await storage.removeAll()
        }
    }
    
    @Test("when setup is called, then application installed event triggered")
    func testApplicationInstalledEvent() async {
        lifecycleTrackingPlugin.setup(analytics: analytics)
        
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 1)
        
        let result = await mockStorage.read()
        let combinedBatch = result.dataItems.map { $0.batch }.joined()
        #expect(combinedBatch.contains(LifecycleEvent.applicationInstalled.rawValue))
    }
    
    @Test("when setup is called, then application opened event triggered")
    func testApplicationOpenedEvent() async {
        lifecycleTrackingPlugin.setup(analytics: analytics)
        
        await mockStorage.waitForCurrentBatchEvents(expectedCount: 2)
        
        let result = await mockStorage.read()
        let combinedBatch = result.dataItems.map { $0.batch }.joined()
        #expect(combinedBatch.contains(LifecycleEvent.applicationOpened.rawValue))
    }
    
    @Test("when app moves background, then application backgrounded event triggered")
    func testApplicationBackgroundedEvent() async {
        lifecycleTrackingPlugin.setup(analytics: analytics)
        
        lifecycleTrackingPlugin.onBackground()
        
        await mockStorage.waitForEventsContaining(LifecycleEvent.applicationBackgrounded.rawValue)
        
        let result = await mockStorage.read()
        let combinedBatch = result.dataItems.map { $0.batch }.joined()
        #expect(combinedBatch.contains(LifecycleEvent.applicationBackgrounded.rawValue))
    }
    
    @Test("when current app version is different, then application updated event triggered")
    func testApplicationUpdatedEvent() async {
        
        mockStorage.write(value: "1.0", key: Constants.storageKeys.appVersion)
        mockStorage.write(value: 10, key: Constants.storageKeys.appBuild)
        
        lifecycleTrackingPlugin.setup(analytics: analytics)
        
        await mockStorage.waitForEventsContaining(LifecycleEvent.applicationUpdated.rawValue)
        
        let result = await mockStorage.read()
        let combinedBatch = result.dataItems.map { $0.batch }.joined()
        #expect(combinedBatch.contains(LifecycleEvent.applicationUpdated.rawValue))
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let mockAnalytics = MockProvider.createMockAnalytics()
        
        lifecycleTrackingPlugin.setup(analytics: mockAnalytics)
        
        #expect(lifecycleTrackingPlugin.analytics != nil)
        #expect(lifecycleTrackingPlugin.pluginType == .utility)
    }
}
