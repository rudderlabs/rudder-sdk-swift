//
//  CustomIntegrationPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 16/10/25.
//

import Testing
@testable import RudderStackAnalytics

struct CustomIntegrationPluginTests {
    
    // MARK: - Basic Protocol Tests
    
    @Test("Given a custom integration plugin, When plugin properties are accessed, Then plugin should have correct type and key")
    func pluginProperties() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        
        mockPlugin.setup(analytics: analytics)
        
        #expect(mockPlugin.pluginType == .terminal)
        #expect(mockPlugin.key == "custom_destination")
        #expect(mockPlugin.analytics === analytics)
    }
    
    @Test("Given a custom plugin without created destination, When getDestinationInstance is called, Then instance should be nil and method should be tracked")
    func getDestinationInstanceWhenNotCreated() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        
        let instance = mockPlugin.getDestinationInstance()
        
        #expect(instance == nil)
        #expect(mockPlugin.getDestinationInstanceCalled == true)
    }
    
    @Test("Given a custom plugin with created destination, When destination is created and getDestinationInstance is called, Then instance should not be nil")
    func getDestinationInstanceWhenCreated() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let config: [String: Any] = [:] // empty config for custom integration
        
        try mockPlugin.create(destinationConfig: config)
        let instance = mockPlugin.getDestinationInstance()
        
        #expect(instance != nil)
        #expect(mockPlugin.getDestinationInstanceCalled == true)
        #expect(instance is MockDestination)
    }
    
    // MARK: - Create Method Tests (Custom integrations)
    
    @Test("Given a custom plugin and valid configuration, When create is called, Then destination should be created successfully")
    func createSuccess() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let config = ["apiKey": "test_key", "enabled": true] as [String: Any]
        
        try mockPlugin.create(destinationConfig: config)
        
        #expect(mockPlugin.createCalled == true)
        #expect(mockPlugin.lastDestinationConfig != nil)
        #expect(mockPlugin.lastDestinationConfig?["apiKey"] as? String == "test_key")
        #expect(mockPlugin.getDestinationInstance() != nil)
    }
    
    @Test("Given a custom plugin with createThrowsError set, When create is called, Then error should be createFailed")
    func createMethodErrorHandling() {
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_key")
        let config: [String: Any] = ["apiKey": "test_key"]
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        
        #expect(throws: MockIntegrationError.createFailed) {
            try mockPlugin.create(destinationConfig: config)
        }
    }
    
    // MARK: - Flush and Reset Tests
    
    @Test("Given a custom plugin, When flush is called, Then flush should be tracked")
    func flush() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        
        mockPlugin.flush()
        
        #expect(mockPlugin.flushCalled == true)
    }
    
    @Test("Given a custom plugin with created destination, When reset is called, Then reset should be tracked and destination cleared")
    func reset() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let config: [String: Any] = ["apiKey": "test_key"]
        
        try mockPlugin.create(destinationConfig: config)
        #expect(mockPlugin.getDestinationInstance() != nil)
        
        mockPlugin.reset()
        
        #expect(mockPlugin.resetCalled == true)
        #expect(mockPlugin.getDestinationInstance() == nil)
    }
    
    // MARK: - Event Handling Tests
    
    @Test("Given a custom plugin and identify event, When identify is called, Then event should be received and stored")
    func identifyEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let identifyEvent = IdentifyEvent()
        
        mockPlugin.identify(payload: identifyEvent)
        
        #expect(mockPlugin.identifyEventReceived != nil)
    }
    
    @Test("Given a custom plugin and track event, When track is called, Then event should be received and stored")
    func trackEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let trackEvent = TrackEvent(event: "Custom Button Clicked")
        
        mockPlugin.track(payload: trackEvent)
        
        #expect(mockPlugin.trackEventReceived != nil)
        #expect(mockPlugin.trackEventReceived?.event == "Custom Button Clicked")
    }
    
    @Test("Given a custom plugin and screen event, When screen is called, Then event should be received and stored")
    func screenEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let screenEvent = ScreenEvent(screenName: "Custom Screen")
        
        mockPlugin.screen(payload: screenEvent)
        
        #expect(mockPlugin.screenEventReceived != nil)
    }
    
    @Test("Given a custom plugin and group event, When group is called, Then event should be received and stored")
    func groupEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let groupEvent = GroupEvent(groupId: "custom_group123")
        
        mockPlugin.group(payload: groupEvent)
        
        #expect(mockPlugin.groupEventReceived != nil)
        #expect(mockPlugin.groupEventReceived?.groupId == "custom_group123")
    }
    
    @Test("Given a custom plugin and alias event, When alias is called, Then event should be received and stored")
    func aliasEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let aliasEvent = AliasEvent(previousId: "old_custom_id", userIdentity: UserIdentity(userId: "new_custom_id"))
        
        mockPlugin.alias(payload: aliasEvent)
        
        #expect(mockPlugin.aliasEventReceived != nil)
    }
    
    // MARK: - Integration with Analytics Tests
    
    @Test("Given a custom plugin setup with analytics that has integration controller, When pluginStore is accessed, Then store should be accessible")
    func pluginStoreAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            stores[mockPlugin.key] = pluginStore
        }
        
        let store = mockPlugin.pluginStore
        
        #expect(store != nil)
        #expect(store === pluginStore)
    }
    
    @Test("Given a custom plugin with plugin store, When pluginChain is accessed, Then chain should be accessible from store")
    func pluginChainAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            stores[mockPlugin.key] = pluginStore
        }
        
        let chain = mockPlugin.pluginChain
        
        #expect(chain != nil)
        #expect(chain === pluginStore.pluginChain)
    }
    
    // MARK: - Custom Integration Specific Tests
    
    @Test("Given a custom integration plugin, When plugin is checked for StandardIntegration conformance, Then plugin should NOT conform to StandardIntegration")
    func customPluginNotStandardIntegration() {
        let analytics = MockProvider.clientWithDiskStorage
        let customPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        customPlugin.setup(analytics: analytics)
        
        #expect(customPlugin.key == "custom_destination")
        #expect(!(customPlugin is StandardIntegration)) // Custom integrations don't conform to StandardIntegration
    }
    
    @Test("Given a custom plugin added to IntegrationsController, When plugin store is created, Then isStandardIntegration should be false")
    func customPluginStoreConfiguration() {
        let analytics = MockProvider.clientWithDiskStorage
        let controller = analytics.integrationsController!
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        
        let pluginStore = controller.integrationPluginStores["custom_destination"]
        #expect(pluginStore != nil)
        #expect(pluginStore?.isStandardIntegration == false)
    }
    
    @Test("Given a custom plugin without destination ready, When onDestinationReady is called, Then callback should be stored for later execution")
    func onDestinationReadyWhenDestinationNotReady() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        var callbackCalled = false
        
        mockPlugin.onDestinationReady { instance, result in
            callbackCalled = true
            _ = instance
            _ = result
        }
        
        // Since destination is not ready, callback should be stored
        #expect(callbackCalled == false)
    }
    
    @Test("Given a custom plugin with ready destination, When onDestinationReady is called, Then callback should be called immediately with success")
    func onDestinationReadyWhenDestinationReadyWithInstance() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockCustomIntegrationPlugin(key: "custom_destination")
        mockPlugin.setup(analytics: analytics)
        var callbackCalled = false
        var receivedInstance: Any?
        var receivedResult: DestinationResult?
        
        let config: [String: Any] = ["apiKey": "test_key"]
        try mockPlugin.create(destinationConfig: config)
        
        // Setup plugin store as ready
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        pluginStore.isDestinationReady = true
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            stores[mockPlugin.key] = pluginStore
        }
        
        mockPlugin.onDestinationReady { instance, result in
            callbackCalled = true
            receivedInstance = instance
            receivedResult = result
        }
        
        #expect(callbackCalled == true)
        #expect(receivedInstance != nil)
        
        switch receivedResult {
        case .success:
            #expect(Bool(true)) // Success case
        case .failure, .none:
            #expect(Bool(false), "Expected success result")
        }
    }
    
    // MARK: - Custom Integration Lifecycle Tests
    
    @Test("Given multiple custom integrations, When they are added to analytics, Then they should all be managed independently")
    func multipleCustomIntegrationsManagement() {
        let analytics = MockProvider.clientWithDiskStorage
        let plugin1 = MockCustomIntegrationPlugin(key: "custom1")
        let plugin2 = MockCustomIntegrationPlugin(key: "custom2")
        let plugin3 = MockCustomIntegrationPlugin(key: "custom3")
        
        analytics.add(plugin: plugin1)
        analytics.add(plugin: plugin2)
        analytics.add(plugin: plugin3)
        
        let controller = analytics.integrationsController!
        #expect(controller.integrationPluginStores["custom1"] != nil)
        #expect(controller.integrationPluginStores["custom2"] != nil)
        #expect(controller.integrationPluginStores["custom3"] != nil)
        
        #expect(controller.integrationPluginStores["custom1"]?.isStandardIntegration == false)
        #expect(controller.integrationPluginStores["custom2"]?.isStandardIntegration == false)
        #expect(controller.integrationPluginStores["custom3"]?.isStandardIntegration == false)
    }
}
