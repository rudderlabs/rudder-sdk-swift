//
//  IntegrationPluginStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import Testing
@testable import RudderStackAnalytics

struct IntegrationPluginStoreTests {
    
    @Test("Given an analytics instance, When IntegrationPluginStore is initialized, Then store should be properly initialized with default values")
    func initialization() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        
        // When
        let store = IntegrationPluginStore(analytics: analytics)
        
        // Then
        #expect(store.analytics != nil)
        #expect(store.pluginChain != nil)
        #expect(store.destinationReadyCallbacks.isEmpty)
        #expect(store.isStandardIntegration == true)
        #expect(store.isDestinationReady == false)
    }
    
    @Test("Given an initialized plugin store, When analytics property is accessed, Then analytics should be the same instance")
    func analyticsProperty() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        let storeAnalytics = pluginStore.analytics
        
        // Then
        #expect(storeAnalytics === analytics)
    }
    
    @Test("Given an initialized plugin store, When pluginChain is accessed, Then pluginChain should be initialized and linked to analytics")
    func pluginChainInitialization() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        let chain = pluginStore.pluginChain
        
        // Then
        #expect(chain != nil)
        #expect(chain?.analytics === analytics)
    }
    
    @Test("Given an initialized plugin store, When destinationReadyCallbacks is accessed, Then callbacks array should be empty")
    func destinationReadyCallbacksInitialization() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        let callbacks = pluginStore.destinationReadyCallbacks
        
        // Then
        #expect(callbacks.isEmpty)
    }
    
    @Test("Given an initialized plugin store, When isStandardIntegration is accessed, Then isStandardIntegration should be true by default")
    func isStandardIntegrationDefaultValue() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        let isStandard = pluginStore.isStandardIntegration
        
        // Then
        #expect(isStandard == true)
    }
    
    @Test("Given an initialized plugin store, When isDestinationReady is accessed, Then isDestinationReady should be false by default")
    func isDestinationReadyDefaultValue() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        let isReady = pluginStore.isDestinationReady
        
        // Then
        #expect(isReady == false)
    }
    
    @Test("Given an initialized plugin store, When isStandardIntegration is modified, Then isStandardIntegration should reflect the new value")
    func isStandardIntegrationModification() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        pluginStore.isStandardIntegration = false
        
        // Then
        #expect(pluginStore.isStandardIntegration == false)
    }
    
    @Test("Given an initialized plugin store, When isDestinationReady is modified, Then isDestinationReady should reflect the new value")
    func isDestinationReadyModification() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        pluginStore.isDestinationReady = true
        
        // Then
        #expect(pluginStore.isDestinationReady == true)
    }
    
    @Test("Given an initialized plugin store, When callback is added to destinationReadyCallbacks, Then callbacks array should contain the added callback")
    func destinationReadyCallbacksModification() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        let callback: IntegrationCallback = { instance, result in
            // Mock callback
        }
        
        // When
        pluginStore.destinationReadyCallbacks.append(callback)
        
        // Then
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
    }
    
    @Test("Given an initialized plugin store, When multiple callbacks are added, Then callbacks array should contain all added callbacks")
    func multipleCallbacksAddition() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        let callback1: IntegrationCallback = { _, _ in }
        let callback2: IntegrationCallback = { _, _ in }
        let callback3: IntegrationCallback = { _, _ in }
        
        // When
        pluginStore.destinationReadyCallbacks.append(callback1)
        pluginStore.destinationReadyCallbacks.append(callback2)
        pluginStore.destinationReadyCallbacks.append(callback3)
        
        // Then
        #expect(pluginStore.destinationReadyCallbacks.count == 3)
    }
    
    @Test("Given an analytics instance, When store is deallocated, Then plugin chain should be deallocated")
    func deinitCleanup() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        var store: IntegrationPluginStore? = IntegrationPluginStore(analytics: analytics)
        
        // Add some callbacks to test cleanup
        let callback: IntegrationCallback = { _, _ in }
        store?.destinationReadyCallbacks.append(callback)
        
        // When
        weak var weakPluginChain = store?.pluginChain
        store = nil
        
        // Then
        #expect(weakPluginChain == nil)
    }
    
    @Test("Given an initialized plugin store, When multiple state changes are made, Then all state should be consistent")
    func stateConsistency() {
        // Given
        let analytics = MockProvider.clientWithDiskStorage
        let pluginStore = IntegrationPluginStore(analytics: analytics)
        
        // When
        pluginStore.isStandardIntegration = false
        pluginStore.isDestinationReady = true
        
        let callback: IntegrationCallback = { _, _ in }
        pluginStore.destinationReadyCallbacks.append(callback)
        
        // Then
        #expect(pluginStore.isStandardIntegration == false)
        #expect(pluginStore.isDestinationReady == true)
        #expect(pluginStore.destinationReadyCallbacks.count == 1)
        #expect(pluginStore.analytics != nil)
        #expect(pluginStore.pluginChain != nil)
    }
}
