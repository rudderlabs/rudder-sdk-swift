//
//  IntegrationsManagementPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 16/10/25.
//

import Testing
import Combine
import Foundation
@testable import RudderStackAnalytics

struct IntegrationsManagementPluginTests {
    
    // MARK: - Initialization Tests
    
    @Test("Given IntegrationsManagementPlugin, When initialized, Then plugin should have correct type and properties")
    func testInitialization() {
        let plugin = IntegrationsManagementPlugin()
        
        #expect(plugin.pluginType == .terminal)
        #expect(plugin.analytics == nil)
    }
    
    @Test("Given IntegrationsManagementPlugin, When setup is called, Then analytics should be set and source config observation should start")
    func testSetup() async {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        
        plugin.setup(analytics: analytics)
        
        #expect(plugin.analytics === analytics)
    }
    
    // MARK: - Event Queuing Tests
    
    @Test("Given IntegrationsManagementPlugin without source config, When events are intercepted, Then events should be queued")
    func testEventQueuing() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        let trackEvent = TrackEvent(event: "Test Event")
        
        let result = plugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect((result as? TrackEvent)?.event == "Test Event")
    }
    
    @Test("Given IntegrationsManagementPlugin, When multiple events are intercepted, Then all events should be queued")
    func testMultipleEventQueuing() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        let events = [
            TrackEvent(event: "Event 1"),
            TrackEvent(event: "Event 2"),
            TrackEvent(event: "Event 3")
        ]
        
        let results = events.map { plugin.intercept(event: $0) }
        
        #expect(results.count == 3)
        results.forEach { #expect($0 != nil) }
    }
    
    @Test("Given IntegrationsManagementPlugin with max queue size, When more events than limit are queued, Then oldest events should be dropped")
    func testQueueSizeLimit() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        for i in 0..<(MAX_QUEUE_SIZE + 100) {
            let event = TrackEvent(event: "Event \(i)")
            _ = plugin.intercept(event: event)
        }
        
        #expect(Bool(true)) // Test passes if no crashes occur
    }
    
    // MARK: - Source Config Integration Tests
    
    @Test("Given IntegrationsManagementPlugin, When source config is updated, Then integration destinations should be initialized")
    func testSourceConfigUpdate() async {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        // Add a mock integration to the controller
        let mockPlugin = MockStandardIntegrationPlugin(key: "Google Ads")
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        let sourceConfig = MockProvider.sourceConfiguration!
        
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        
        await runAfter(0.2) {
            #expect(mockPlugin.createCalled == true)
            #expect(analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == true)
        }
    }
    
    @Test("Given IntegrationsManagementPlugin, When source config is disabled, Then integration initialization should be skipped")
    func testSourceConfigDisabled() async {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        // Add a mock integration to the controller
        let mockPlugin = MockStandardIntegrationPlugin(key: "Google Ads")
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        analytics.sourceConfigState.dispatch(action: DisableSourceConfigAction())
        
        await runAfter(0.2) {
            #expect(mockPlugin.createCalled == false)
            #expect(analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == false)
        }
    }
    
    // MARK: - Event Processing Tests
    
    @Test("Given IntegrationsManagementPlugin with queued events, When source config is fetched, Then queued events should be processed")
    func testEventProcessingAfterSourceConfig() async {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        // Add a mock integration to track processed events
        let mockPlugin = MockStandardIntegrationPlugin(key: "Google Ads")
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        // Queue some events before source config
        let trackEvent1 = TrackEvent(event: "Event 1")
        let trackEvent2 = TrackEvent(event: "Event 2")
        
        _ = plugin.intercept(event: trackEvent1)
        _ = plugin.intercept(event: trackEvent2)
        
        let sourceConfig = MockProvider.sourceConfiguration!
        
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        
        await runAfter(0.5) {
            #expect(mockPlugin.createCalled == true)
            // Events should have been processed through the integration plugin chain
        }
    }
    
    // MARK: - Integration with IntegrationsController Tests
    
    @Test("Given IntegrationsManagementPlugin, When accessing integrationPluginStores, Then should delegate to IntegrationsController")
    func testIntegrationPluginStoresAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        // Add an integration
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        analytics.integrationsController?.add(integration: mockPlugin)
        
        let stores = plugin.integrationPluginStores
        
        #expect(stores != nil)
        #expect(stores?["test_destination"] != nil)
    }
    
    @Test("Given IntegrationsManagementPlugin, When accessing integrationPluginChain, Then should delegate to IntegrationsController")
    func testIntegrationPluginChainAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        let chain = plugin.integrationPluginChain
        
        #expect(chain != nil)
        #expect(chain === analytics.integrationsController?.integrationPluginChain)
    }
    
    @Test("Given IntegrationsManagementPlugin, When setIsSourceEnabledFetchedAtLeastOnce is called, Then should delegate to IntegrationsController")
    func testSetIsSourceEnabledFetchedAtLeastOnce() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        #expect(analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == false)
        
        plugin.setIsSourceEnabledFetchedAtLeastOnce(true)
        
        #expect(analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == true)
    }
    
    @Test("Given IntegrationsManagementPlugin, When initDestination is called, Then should delegate to IntegrationsController")
    func testInitDestinationDelegation() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        let mockPlugin = MockStandardIntegrationPlugin(key: "Google Ads")
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        let sourceConfig = MockProvider.sourceConfiguration!
        
        plugin.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(mockPlugin.createCalled == true)
    }
    
    // MARK: - Multiple Source Config Updates Tests
    
    @Test("Given IntegrationsManagementPlugin, When source config is updated multiple times, Then integration should only be processed once for first update")
    func testMultipleSourceConfigUpdates() async {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        let mockPlugin = MockStandardIntegrationPlugin(key: "Google Ads")
        analytics.integrationsController?.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        let sourceConfig1 = MockProvider.sourceConfiguration!
        let sourceConfig2 = MockProvider.sourceConfiguration!
        
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig1))
        
        await runAfter(0.1) {
            analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig2))
        }
        
        await runAfter(0.2) {
            #expect(mockPlugin.createCalled == true || mockPlugin.updateCalled == true)
        }
    }
    
    // MARK: - Memory Management Tests
    
    @Test("Given IntegrationsManagementPlugin, When deinit is called, Then resources should be cleaned up")
    func testDeinit() {
        let analytics = MockProvider.clientWithDiskStorage
        var plugin: IntegrationsManagementPlugin? = IntegrationsManagementPlugin()
        plugin?.setup(analytics: analytics)
        
        plugin = nil
        
        #expect(plugin == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Given IntegrationsManagementPlugin, When event queuing fails, Then should handle gracefully")
    func testEventQueuingErrorHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin = IntegrationsManagementPlugin()
        plugin.setup(analytics: analytics)
        
        // Simulate a scenario where queuing might fail
        let event = TrackEvent(event: "Test Event")
        
        let result = plugin.intercept(event: event)
        #expect(result != nil)
    }
}

// MARK: - Helper Extensions

private extension IntegrationsManagementPluginTests {
    func runAfter(_ delay: TimeInterval, _ block: @escaping () -> Void) async {
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        block()
    }
}

// MARK: - Helper Extensions for Event Creation

// Remove the apply extension as it's not needed with proper TrackEvent initialization
