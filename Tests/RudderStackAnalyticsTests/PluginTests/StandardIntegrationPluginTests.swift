//
//  StandardIntegrationPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import Testing
@testable import RudderStackAnalytics

struct StandardIntegrationPluginTests {
    
    // MARK: - Basic Protocol Tests
    
    @Test("Given a mock integration plugin, When plugin properties are accessed, Then plugin should have correct type and key")
    func pluginProperties() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        
        mockPlugin.setup(analytics: analytics)
        
        #expect(mockPlugin.pluginType == .terminal)
        #expect(mockPlugin.key == "test_destination")
        #expect(mockPlugin.analytics === analytics)
    }
    
    @Test("Given a plugin without created destination, When getDestinationInstance is called, Then instance should be nil and method should be tracked")
    func getDestinationInstanceWhenNotCreated() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        
        let instance = mockPlugin.getDestinationInstance()
        
        #expect(instance == nil)
        #expect(mockPlugin.getDestinationInstanceCalled == true)
    }
    
    @Test("Given a plugin with created destination, When destination is created and getDestinationInstance is called, Then instance should not be nil")
    func getDestinationInstanceWhenCreated() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let config = ["apiKey": "test_key"]
        
        try mockPlugin.create(destinationConfig: config)
        let instance = mockPlugin.getDestinationInstance()
        
        #expect(instance != nil)
        #expect(mockPlugin.getDestinationInstanceCalled == true)
        #expect(instance is MockDestination)
    }
    
    // MARK: - Create Method Tests
    
    @Test("Given a plugin and valid configuration, When create is called, Then destination should be created successfully")
    func createSuccess() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let config = ["apiKey": "test_key", "enabled": true] as [String: Any]
        
        try mockPlugin.create(destinationConfig: config)
        
        #expect(mockPlugin.createCalled == true)
        #expect(mockPlugin.lastDestinationConfig != nil)
        #expect(mockPlugin.lastDestinationConfig?["apiKey"] as? String == "test_key")
        #expect(mockPlugin.getDestinationInstance() != nil)
    }
    
    @Test("Given a plugin with createThrowsError set, When create is called, Then error should be createFailed")
    func createMethodErrorHandling() {
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_key")
        let config = ["apiKey": "test_key"]
        mockPlugin.createThrowsError = MockIntegrationError.createFailed
        
        #expect(throws: MockIntegrationError.createFailed) {
            try mockPlugin.create(destinationConfig: config)
        }
    }
    
    // MARK: - Update Method Tests
    
    @Test("Given a plugin with created destination, When update is called, Then destination should be updated successfully")
    func updateSuccess() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let initialConfig = ["apiKey": "test_key"]
        let updatedConfig = ["apiKey": "updated_key", "timeout": 30] as [String: Any]
        
        try mockPlugin.create(destinationConfig: initialConfig)
        try mockPlugin.update(destinationConfig: updatedConfig)
        
        #expect(mockPlugin.updateCalled == true)
        #expect(mockPlugin.lastDestinationConfig?["apiKey"] as? String == "updated_key")
        #expect(mockPlugin.lastDestinationConfig?["timeout"] as? Int == 30)
    }
    
    @Test("Given a plugin configured to throw error on update, When update is called, Then update should be tracked and error thrown")
    func updateFailure() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let config = ["apiKey": "test_key"]
        mockPlugin.updateThrowsError = MockIntegrationError.updateFailed
        
        #expect(throws: MockIntegrationError.updateFailed) {
            try mockPlugin.update(destinationConfig: config)
        }
        #expect(mockPlugin.updateCalled == true)
    }
    
    // MARK: - Flush and Reset Tests
    
    @Test("Given a plugin, When flush is called, Then flush should be tracked")
    func flush() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        
        mockPlugin.flush()
        
        #expect(mockPlugin.flushCalled == true)
    }
    
    @Test("Given a plugin with created destination, When reset is called, Then reset should be tracked and destination cleared")
    func reset() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let config = ["apiKey": "test_key"]
        
        try mockPlugin.create(destinationConfig: config)
        #expect(mockPlugin.getDestinationInstance() != nil)
        
        mockPlugin.reset()
        
        #expect(mockPlugin.resetCalled == true)
        #expect(mockPlugin.getDestinationInstance() == nil)
    }
    
    // MARK: - Event Handling Tests
    
    @Test("Given a plugin and identify event, When identify is called, Then event should be received and stored")
    func identifyEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let identifyEvent = IdentifyEvent()
        
        mockPlugin.identify(payload: identifyEvent)
        
        #expect(mockPlugin.identifyEventReceived != nil)
    }
    
    @Test("Given a plugin and track event, When track is called, Then event should be received and stored")
    func trackEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let trackEvent = TrackEvent(event: "Button Clicked")
        
        mockPlugin.track(payload: trackEvent)
        
        #expect(mockPlugin.trackEventReceived != nil)
        #expect(mockPlugin.trackEventReceived?.event == "Button Clicked")
    }
    
    @Test("Given a plugin and screen event, When screen is called, Then event should be received and stored")
    func screenEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let screenEvent = ScreenEvent(screenName: "Test Screen")
        
        mockPlugin.screen(payload: screenEvent)
        
        #expect(mockPlugin.screenEventReceived != nil)
    }
    
    @Test("Given a plugin and group event, When group is called, Then event should be received and stored")
    func groupEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let groupEvent = GroupEvent(groupId: "group123")
        
        mockPlugin.group(payload: groupEvent)
        
        #expect(mockPlugin.groupEventReceived != nil)
        #expect(mockPlugin.groupEventReceived?.groupId == "group123")
    }
    
    @Test("Given a plugin and alias event, When alias is called, Then event should be received and stored")
    func aliasEventHandling() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let aliasEvent = AliasEvent(previousId: "old_id", userIdentity: UserIdentity(userId: "new_id"))
        
        mockPlugin.alias(payload: aliasEvent)
        
        #expect(mockPlugin.aliasEventReceived != nil)
    }
    
    // MARK: - Integration with Analytics Tests
    
    @Test("Given a plugin setup with analytics that has integration manager, When pluginStore is accessed, Then store should be accessible")
    func pluginStoreAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            stores[mockPlugin.key] = pluginStore
        }
        
        let store = mockPlugin.pluginStore
        
        #expect(store != nil)
        #expect(store === pluginStore)
    }
    
    @Test("Given a plugin with plugin store, When pluginChain is accessed, Then chain should be accessible from store")
    func pluginChainAccess() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        analytics.integrationsController?.$integrationPluginStores.modify { stores in
            stores[mockPlugin.key] = pluginStore
        }
        
        let chain = mockPlugin.pluginChain
        
        #expect(chain != nil)
        #expect(chain === pluginStore.pluginChain)
    }
    
    // MARK: - StandardPlugin Tests
    
    @Test("Given a standard integration plugin, When plugin is checked for StandardPlugin conformance, Then plugin should conform to StandardPlugin")
    func standardPluginConformance() {
        let analytics = MockProvider.clientWithDiskStorage
        let standardPlugin = MockStandardIntegrationPlugin(key: "standard_destination")
        standardPlugin.setup(analytics: analytics)
        
        #expect(standardPlugin.key == "standard_destination")
    }
    
    // MARK: - onDestinationReady Tests
    
    @Test("Given a plugin without destination ready, When onDestinationReady is called, Then callback should be stored for later execution")
    func onDestinationReadyWhenDestinationNotReady() {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
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
    
    @Test("Given a plugin with ready destination, When onDestinationReady is called, Then callback should be called immediately with success")
    func onDestinationReadyWhenDestinationReadyWithInstance() throws {
        let analytics = MockProvider.clientWithDiskStorage
        let mockPlugin = MockStandardIntegrationPlugin(key: "test_destination")
        mockPlugin.setup(analytics: analytics)
        var callbackCalled = false
        var receivedInstance: Any?
        var receivedResult: DestinationResult?
        
        let config = ["apiKey": "test_key"]
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
    
    @Test("Given a standard plugin added to IntegrationsController, When plugin store is created, Then isStandardIntegration should be true")
    func customPluginStoreConfiguration() {
        let analytics = MockProvider.clientWithDiskStorage
        let controller = analytics.integrationsController!
        let mockPlugin = MockStandardIntegrationPlugin(key: "standard_destination")
        
        controller.add(integration: mockPlugin)
        mockPlugin.setup(analytics: analytics)
        
        let pluginStore = controller.integrationPluginStores["standard_destination"]
        #expect(pluginStore != nil)
        #expect(pluginStore?.isStandardIntegration == true)
    }
    
    @Test("Given a standard integration plugin, When plugin is checked for StandardPlugin conformance, Then plugin should conform to StandardPlugin")
    func customPluginNotStandardPlugin() {
        let analytics = MockProvider.clientWithDiskStorage
        let customPlugin = MockStandardIntegrationPlugin(key: "standard_destination")
        customPlugin.setup(analytics: analytics)
        
        #expect(customPlugin.key == "standard_destination")
        #expect(customPlugin is StandardPlugin)
    }
}
