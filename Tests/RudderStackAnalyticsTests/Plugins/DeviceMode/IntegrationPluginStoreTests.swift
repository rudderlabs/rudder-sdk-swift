//
//  IntegrationPluginStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("IntegrationPluginStore Tests")
struct IntegrationPluginStoreTests {
    
    var analytics: Analytics
    
    init() {
        let mockConfiguration = MockProvider.createMockConfiguration()
        mockConfiguration.flushPolicies = []
        
        self.analytics = Analytics(configuration: mockConfiguration)
    }
    
    @Test("given an analytics instance, when IntegrationPluginStore is initialized, then store should be properly initialized with default values")
    func initialization() {
        let store = IntegrationPluginStore(analytics: analytics)
        
        #expect(store.analytics != nil)
        #expect(store.pluginChain != nil)
        #expect(store.destinationReadyCallbacks.isEmpty)
        #expect(store.isStandardIntegration)
        #expect(!store.isDestinationReady)
    }
    
    @Test("given an initialized plugin store, when analytics property is accessed, then analytics should be the same instance")
    func analyticsProperty() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let storeAnalytics = pluginStore.analytics
        
        #expect(storeAnalytics === analytics)
    }
    
    @Test("given an initialized plugin store, when pluginChain is accessed, then pluginChain should be initialized and linked to analytics")
    func pluginChainInitialization() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let chain = pluginStore.pluginChain
        
        #expect(chain != nil)
        #expect(chain?.analytics === analytics)
    }
    
    @Test("given an initialized plugin store, when destinationReadyCallbacks is accessed, then callbacks array should be empty")
    func destinationReadyCallbacksInitialization() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let callbacks = pluginStore.destinationReadyCallbacks
        
        #expect(callbacks.isEmpty)
    }
    
    @Test("given an initialized plugin store, when isStandardIntegration is accessed, then isStandardIntegration should be true by default")
    func isStandardIntegrationDefaultValue() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let isStandard = pluginStore.isStandardIntegration
        
        #expect(isStandard)
    }
    
    @Test("given an initialized plugin store, when isDestinationReady is accessed, then isDestinationReady should be false by default")
    func isDestinationReadyDefaultValue() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        let isReady = pluginStore.isDestinationReady
        
        #expect(!isReady)
    }
    
    @Test("given an initialized plugin store, when isStandardIntegration is modified, then isStandardIntegration should reflect the new value")
    func isStandardIntegrationModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isStandardIntegration = false
        
        #expect(!pluginStore.isStandardIntegration)
    }
    
    @Test("given an initialized plugin store, when isDestinationReady is modified, then isDestinationReady should reflect the new value")
    func isDestinationReadyModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isDestinationReady = true
        
        #expect(pluginStore.isDestinationReady)
    }
    
    @Test("given an initialized plugin store, when callback is added to destinationReadyCallbacks, then callbacks array should contain the added callback")
    func destinationReadyCallbacksModification() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        let callback: IntegrationCallback = { instance, result in
            // Mock callback
        }
        
        pluginStore.destinationReadyCallbacks.append(callback)
        
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
    }
    
    @Test("given an initialized plugin store, when multiple callbacks are added, then callbacks array should contain all added callbacks")
    func multipleCallbacksAddition() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        var emptyCallBack: IntegrationCallback {
            return { _, _ in
                /* Default implementation (no-op) */
            }
        }
        
        pluginStore.destinationReadyCallbacks.append(emptyCallBack)
        pluginStore.destinationReadyCallbacks.append(emptyCallBack)
        pluginStore.destinationReadyCallbacks.append(emptyCallBack)
        
        #expect(pluginStore.destinationReadyCallbacks.count == 3)
    }
    
    @Test("given an analytics instance, when store is deallocated, then plugin chain should be deallocated")
    func deinitCleanup() {
        weak var weakPluginChain: PluginChain?
        
        do {
            let store = IntegrationPluginStore(analytics: analytics)
            
            let callback: IntegrationCallback = { _, _ in
                /* Default implementation (no-op) */
            }
            store.destinationReadyCallbacks.append(callback)
            weakPluginChain = store.pluginChain
        }
        
        // After the do–scope ends, store is deallocated automatically
        #expect(weakPluginChain == nil)
    }
    
    @Test("given an initialized plugin store, when multiple state changes are made, then all state should be consistent")
    func stateConsistency() {
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        pluginStore.isStandardIntegration = false
        pluginStore.isDestinationReady = true
        
        let callback: IntegrationCallback = { _, _ in
            /* Default implementation (no-op) */
        }
        pluginStore.destinationReadyCallbacks.append(callback)
        
        #expect(!pluginStore.isStandardIntegration)
        #expect(pluginStore.isDestinationReady)
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
        #expect(pluginStore.analytics != nil)
        #expect(pluginStore.pluginChain != nil)
    }
}
