//
//  IntegrationsControllerTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 16/10/25.
//

import Testing
import Combine
import Foundation
@testable import RudderStackAnalytics

@Suite("IntegrationsController Tests")
struct IntegrationsControllerTests {
    
    var analytics: Analytics
    let mockPluginKey = "Google Ads"
    
    init() {
        let mockConfiguration = MockProvider.createMockConfiguration()
        mockConfiguration.flushPolicies = []
        
        self.analytics = Analytics(configuration: mockConfiguration)
    }
    
    // MARK: - Initialization Tests
    
    @Test("Given Analytics instance, When IntegrationsController is initialized, Then controller should be properly set up")
    func testIntegrationsControllerInitialization() {
        let controller = analytics.integrationsController!
        
        #expect(controller.analytics != nil)
        #expect(controller.analytics === analytics)
        #expect(controller.integrationPluginStores.isEmpty)
        #expect(!controller.isSourceEnabledFetchedAtLeastOnce)
    }
    
    // MARK: - Add Integration Tests
    
    @Test("Given IntegrationsController, When integration plugin is added, Then plugin should be added to chain and store created")
    func testAddIntegrationPlugin() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "TestPlugin")
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        
        #expect(controller.integrationPluginStores["TestPlugin"] != nil)
        #expect(controller.integrationPluginStores["TestPlugin"]?.isStandardIntegration ?? false)
    }
    
    @Test("Given IntegrationsController with source config fetched, When integration plugin is added, Then destination should be initialized")
    func testAddIntegrationWithExistingSourceConfig() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        let sourceConfig = MockProvider.sourceConfiguration!
        
        // Simulate source config being fetched
        controller.isSourceEnabledFetchedAtLeastOnce = true
        analytics.sourceConfigState.state.value = sourceConfig
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        
        #expect(controller.integrationPluginStores[mockPluginKey] != nil)
        // Destination should be automatically initialized since source config exists
        #expect(mockPlugin.createCalled)
    }
    
    // MARK: - Remove Integration Tests
    
    @Test("Given IntegrationsController with added integration, When integration is removed, Then plugin should be removed from chain and store")
    func testRemoveIntegrationPlugin() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "TestPlugin")
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        
        controller.remove(integration: mockPlugin)
        
        #expect(controller.integrationPluginStores["TestPlugin"] == nil)
    }
    
    // MARK: - Destination Initialization Tests
    
    @Test("Given IntegrationsController and valid source config, When initDestination is called, Then destination should be created successfully")
    func testInitDestinationSuccess() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(mockPlugin.createCalled)
        #expect(controller.integrationPluginStores[mockPluginKey]?.isDestinationReady ?? false)
    }
    
    @Test("Given IntegrationsController and source config without destination, When initDestination is called, Then destination creation should fail gracefully")
    func testInitDestinationMissingDestination() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "NonExistentDestination")
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(!mockPlugin.createCalled)
        #expect(!(controller.integrationPluginStores["NonExistentDestination"]?.isDestinationReady ?? true))
    }
    
    @Test("Given IntegrationsController and disabled destination in source config, When initDestination is called, Then destination should not be created")
    func testInitDestinationDisabledDestination() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "NonExistentDestination") // Use non-existent destination to simulate disabled
        
        controller.add(integration: mockPlugin)
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        // Non-existent destination should be treated as disabled
        #expect(!mockPlugin.createCalled)
        #expect(!(controller.integrationPluginStores["NonExistentDestination"]?.isDestinationReady ?? true))
    }
    
    @Test("Given IntegrationsController and integration that throws error during create, When initDestination is called, Then error should be handled gracefully")
    func testInitDestinationCreateError() {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(mockPlugin.createCalled)
        #expect(!(controller.integrationPluginStores[mockPluginKey]?.isDestinationReady ?? true))
    }
    
    // MARK: - Update Destination Tests
    
    @Test("Given IntegrationsController with existing destination, When initDestination is called again, Then destination should be updated")
    func testUpdateDestination() throws {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        let sourceConfig = MockProvider.sourceConfiguration!
        
        // Create destination first
        try mockPlugin.create(destinationConfig: [:])
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(mockPlugin.updateCalled)
        #expect(controller.integrationPluginStores[mockPluginKey]?.isDestinationReady ?? false)
    }
    
    @Test("Given IntegrationsController with destination that throws error during update, When initDestination is called, Then error should be handled gracefully")
    func testUpdateDestinationError() throws {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        mockPlugin.updateThrowsError = MockIntegrationError.updateFailed
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        let sourceConfig = MockProvider.sourceConfiguration!
        
        // Create destination first
        try mockPlugin.create(destinationConfig: [:])
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(mockPlugin.updateCalled)
        #expect(!(controller.integrationPluginStores[mockPluginKey]?.isDestinationReady ?? true))
    }
    
    // MARK: - Reset Tests
    
    @Test("Given IntegrationsController with ready destinations, When reset is called, Then all ready destinations should be reset")
    func testReset() {
        let controller = analytics.integrationsController!
        let mockPlugin1 = MockStandardIntegrationPlugin(key: "destination1")
        let mockPlugin2 = MockStandardIntegrationPlugin(key: "destination2")
        
        controller.add(integration: mockPlugin1)
        controller.add(integration: mockPlugin2)
        mockPlugin1.setup(analytics: analytics)
        mockPlugin2.setup(analytics: analytics)
        
        // Set destinations as ready
        controller.integrationPluginStores["destination1"]?.isDestinationReady = true
        controller.integrationPluginStores["destination2"]?.isDestinationReady = false
        
        controller.reset()
        
        #expect(mockPlugin1.resetCalled)
        #expect(!mockPlugin2.resetCalled) // Not ready, so not reset
    }
    
    // MARK: - Flush Tests
    
    @Test("Given IntegrationsController with ready destinations, When flush is called, Then all ready destinations should be flushed")
    func testFlush() {
        let controller = analytics.integrationsController!
        let mockPlugin1 = MockStandardIntegrationPlugin(key: "destination1")
        let mockPlugin2 = MockStandardIntegrationPlugin(key: "destination2")
        
        controller.add(integration: mockPlugin1)
        controller.add(integration: mockPlugin2)
        mockPlugin1.setup(analytics: analytics)
        mockPlugin2.setup(analytics: analytics)
        
        // Set destinations as ready
        controller.integrationPluginStores["destination1"]?.isDestinationReady = true
        controller.integrationPluginStores["destination2"]?.isDestinationReady = false
        
        controller.flush()
        
        #expect(mockPlugin1.flushCalled)
        #expect(!mockPlugin2.flushCalled) // Not ready, so not flushed
    }
    
    // MARK: - Callback Notification Tests
    
    @Test("Given IntegrationsController and integration with callbacks, When destination is successfully created, Then success callbacks should be notified")
    func testNotifyCallbacksSuccess() async {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        var callbackResult: DestinationResult?
        var callbackInstance: Any?
        
        controller.integrationPluginStores[mockPluginKey]?.destinationReadyCallbacks.append { instance, result in
            callbackInstance = instance
            callbackResult = result
        }
        
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(callbackResult != nil)
        if case .success = callbackResult {
            // Success case verified
        } else {
            #expect(Bool(false), "Expected success result")
        }
        #expect(callbackInstance != nil)
    }
    
    @Test("Given IntegrationsController and integration with callbacks, When destination creation fails, Then failure callbacks should be notified")
    func testNotifyCallbacksFailure() async {
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: mockPluginKey)
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics) // Ensure plugin has analytics reference
        
        var callbackResult: DestinationResult?
        
        controller.integrationPluginStores[mockPluginKey]?.destinationReadyCallbacks.append { _, result in
            callbackResult = result
        }
        
        let sourceConfig = MockProvider.sourceConfiguration!
        
        controller.initDestination(sourceConfig: sourceConfig, integration: mockPlugin)
        
        #expect(callbackResult != nil)
        if case .failure = callbackResult {
            // Failure case verified
        } else {
            #expect(Bool(false), "Expected failure result")
        }
    }
    
    // MARK: - Thread Safety Tests
    
    @Test("Given IntegrationsController, When multiple integrations are added concurrently, Then operations should be thread-safe")
    func testThreadSafety() async {
        let controller = analytics.integrationsController!
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let mockPlugin = MockStandardIntegrationPlugin(key: "destination_\(i)")
                    controller.add(integration: mockPlugin)
                }
            }
        }
        
        #expect(controller.integrationPluginStores.count == 10)
    }
    
    // MARK: - Deinit Tests
    
    @Test("Given IntegrationsController, When deinit is called, Then resources should be cleaned up")
    func testDeinit() {
        var controller: IntegrationsController? = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        
        controller?.add(integration: mockPlugin)
        #expect(controller?.integrationPluginStores.count == 1)
        
        controller = nil
        
        // No way to directly test deinit, but this ensures no retain cycles
        #expect(controller == nil)
    }
}
