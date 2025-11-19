//
//  IntegrationPluginStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import Testing
@testable import RudderStackAnalytics

struct IntegrationPluginStoreTests {
    
    var analytics: Analytics
    
    init() {
        let mockConfiguration = MockProvider.createMockConfiguration()
        mockConfiguration.flushPolicies = []
        
        self.analytics = Analytics(configuration: mockConfiguration)
    }
    
    @Test("Given an analytics instance, When IntegrationPluginStore is initialized, Then store should be properly initialized with default values")
    func initialization() {
        let store = IntegrationPluginStore(analytics: analytics)
        
        #expect(store.analytics != nil)
        #expect(store.pluginChain != nil)
        #expect(store.destinationReadyCallbacks.isEmpty)
        #expect(store.isStandardIntegration == true)
        #expect(store.isDestinationReady == false)
    }
    
    @Test("Given an initialized plugin store, When analytics property is accessed, Then analytics should be the same instance")
    func analyticsProperty() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let storeAnalytics = pluginStore.analytics
        
        #expect(storeAnalytics === analytics)
    }
    
    @Test("Given an initialized plugin store, When pluginChain is accessed, Then pluginChain should be initialized and linked to analytics")
    func pluginChainInitialization() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let chain = pluginStore.pluginChain
        
        #expect(chain != nil)
        #expect(chain?.analytics === analytics)
    }
    
    @Test("Given an initialized plugin store, When destinationReadyCallbacks is accessed, Then callbacks array should be empty")
    func destinationReadyCallbacksInitialization() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let callbacks = pluginStore.destinationReadyCallbacks
        
        #expect(callbacks.isEmpty)
    }
    
    @Test("Given an initialized plugin store, When isStandardIntegration is accessed, Then isStandardIntegration should be true by default")
    func isStandardIntegrationDefaultValue() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let isStandard = pluginStore.isStandardIntegration
        
        #expect(isStandard == true)
    }
    
    @Test("Given an initialized plugin store, When isDestinationReady is accessed, Then isDestinationReady should be false by default")
    func isDestinationReadyDefaultValue() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let isReady = pluginStore.isDestinationReady
        
        #expect(isReady == false)
    }
    
    @Test("Given an initialized plugin store, When isStandardIntegration is modified, Then isStandardIntegration should reflect the new value")
    func isStandardIntegrationModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isStandardIntegration = false
        
        #expect(pluginStore.isStandardIntegration == false)
    }
    
    @Test("Given an initialized plugin store, When isDestinationReady is modified, Then isDestinationReady should reflect the new value")
    func isDestinationReadyModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isDestinationReady = true
        
        #expect(pluginStore.isDestinationReady == true)
    }
    
    @Test("Given an initialized plugin store, When callback is added to destinationReadyCallbacks, Then callbacks array should contain the added callback")
    func destinationReadyCallbacksModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        let callback: IntegrationCallback = { instance, result in
            // Mock callback
        }
        
        pluginStore.destinationReadyCallbacks.append(callback)
        
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
    }
    
    @Test("Given an initialized plugin store, When multiple callbacks are added, Then callbacks array should contain all added callbacks")
    func multipleCallbacksAddition() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        let callback1: IntegrationCallback = { _, _ in }
        let callback2: IntegrationCallback = { _, _ in }
        let callback3: IntegrationCallback = { _, _ in }
        
        pluginStore.destinationReadyCallbacks.append(callback1)
        pluginStore.destinationReadyCallbacks.append(callback2)
        pluginStore.destinationReadyCallbacks.append(callback3)
        
        #expect(pluginStore.destinationReadyCallbacks.count == 3)
    }
    
    @Test("Given an analytics instance, When store is deallocated, Then plugin chain should be deallocated")
    func deinitCleanup() {
        var store: IntegrationPluginStore? = IntegrationPluginStore(analytics: analytics)
        
        let callback: IntegrationCallback = { _, _ in }
        store?.destinationReadyCallbacks.append(callback)
        
        weak var weakPluginChain = store?.pluginChain
        store = nil
        
        #expect(weakPluginChain == nil)
    }
    
    @Test("Given an initialized plugin store, When multiple state changes are made, Then all state should be consistent")
    func stateConsistency() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isStandardIntegration = false
        pluginStore.isDestinationReady = true
        
        let callback: IntegrationCallback = { _, _ in }
        pluginStore.destinationReadyCallbacks.append(callback)
        
        #expect(pluginStore.isStandardIntegration == false)
        #expect(pluginStore.isDestinationReady == true)
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
        #expect(pluginStore.analytics != nil)
        #expect(pluginStore.pluginChain != nil)
    }
}
