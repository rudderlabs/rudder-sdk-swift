//
//  IntegrationPluginStoreTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import XCTest
@testable import RudderStackAnalytics

final class IntegrationPluginStoreTests: XCTestCase {
    
    var analytics: Analytics!
    var pluginStore: IntegrationPluginStore!
    
    override func setUp() {
        super.setUp()
        analytics = MockProvider.clientWithDiskStorage
        pluginStore = IntegrationPluginStore(analytics: analytics)
    }
    
    override func tearDown() {
        pluginStore = nil
        analytics = nil
        super.tearDown()
    }
    
    func test_initialization() {
        given("An analytics instance") {
            let analytics = MockProvider.clientWithDiskStorage
            
            when("IntegrationPluginStore is initialized") {
                let store = IntegrationPluginStore(analytics: analytics)
                
                then("store should be properly initialized with default values") {
                    XCTAssertNotNil(store.analytics)
                    XCTAssertNotNil(store.pluginChain)
                    XCTAssertTrue(store.destinationReadyCallbacks.isEmpty)
                    XCTAssertTrue(store.isStandardIntegration)
                    XCTAssertFalse(store.isDestinationReady)
                }
            }
        }
    }
    
    func test_analytics_property() {
        given("An initialized plugin store") {
            when("analytics property is accessed") {
                let storeAnalytics = pluginStore.analytics
                
                then("analytics should be the same instance") {
                    XCTAssertTrue(storeAnalytics === analytics)
                }
            }
        }
    }
    
    func test_pluginChain_initialization() {
        given("An initialized plugin store") {
            when("pluginChain is accessed") {
                let chain = pluginStore.pluginChain
                
                then("pluginChain should be initialized and linked to analytics") {
                    XCTAssertNotNil(chain)
                    XCTAssertTrue(chain?.analytics === analytics)
                }
            }
        }
    }
    
    func test_destinationReadyCallbacks_initialization() {
        given("An initialized plugin store") {
            when("destinationReadyCallbacks is accessed") {
                let callbacks = pluginStore.destinationReadyCallbacks
                
                then("callbacks array should be empty") {
                    XCTAssertTrue(callbacks.isEmpty)
                }
            }
        }
    }
    
    func test_isStandardIntegration_defaultValue() {
        given("An initialized plugin store") {
            when("isStandardIntegration is accessed") {
                let isStandard = pluginStore.isStandardIntegration
                
                then("isStandardIntegration should be true by default") {
                    XCTAssertTrue(isStandard)
                }
            }
        }
    }
    
    func test_isDestinationReady_defaultValue() {
        given("An initialized plugin store") {
            when("isDestinationReady is accessed") {
                let isReady = pluginStore.isDestinationReady
                
                then("isDestinationReady should be false by default") {
                    XCTAssertFalse(isReady)
                }
            }
        }
    }
    
    func test_isStandardIntegration_modification() {
        given("An initialized plugin store") {
            when("isStandardIntegration is modified") {
                pluginStore.isStandardIntegration = false
                
                then("isStandardIntegration should reflect the new value") {
                    XCTAssertFalse(pluginStore.isStandardIntegration)
                }
            }
        }
    }
    
    func test_isDestinationReady_modification() {
        given("An initialized plugin store") {
            when("isDestinationReady is modified") {
                pluginStore.isDestinationReady = true
                
                then("isDestinationReady should reflect the new value") {
                    XCTAssertTrue(pluginStore.isDestinationReady)
                }
            }
        }
    }
    
    func test_destinationReadyCallbacks_modification() {
        given("An initialized plugin store") {
            let callback: IntegrationCallback = { instance, result in
                // Mock callback
            }
            
            when("callback is added to destinationReadyCallbacks") {
                pluginStore.destinationReadyCallbacks.append(callback)
                
                then("callbacks array should contain the added callback") {
                    XCTAssertEqual(pluginStore.destinationReadyCallbacks.count, 1)
                }
            }
        }
    }
    
    func test_multiple_callbacks_addition() {
        given("An initialized plugin store") {
            let callback1: IntegrationCallback = { _, _ in }
            let callback2: IntegrationCallback = { _, _ in }
            let callback3: IntegrationCallback = { _, _ in }
            
            when("multiple callbacks are added") {
                pluginStore.destinationReadyCallbacks.append(callback1)
                pluginStore.destinationReadyCallbacks.append(callback2)
                pluginStore.destinationReadyCallbacks.append(callback3)
                
                then("callbacks array should contain all added callbacks") {
                    XCTAssertEqual(pluginStore.destinationReadyCallbacks.count, 3)
                }
            }
        }
    }
    
    func test_deinit_cleanup() {
        given("An analytics instance") {
            let analytics = MockProvider.clientWithDiskStorage
            var store: IntegrationPluginStore? = IntegrationPluginStore(analytics: analytics)
            
            // Add some callbacks to test cleanup
            let callback: IntegrationCallback = { _, _ in }
            store?.destinationReadyCallbacks.append(callback)
            
            when("store is deallocated") {
                weak var weakPluginChain = store?.pluginChain
                store = nil
                
                then("plugin chain should be deallocated") {
                    XCTAssertNil(weakPluginChain)
                }
            }
        }
    }
    
    func test_state_consistency() {
        given("An initialized plugin store") {
            when("multiple state changes are made") {
                pluginStore.isStandardIntegration = false
                pluginStore.isDestinationReady = true
                
                let callback: IntegrationCallback = { _, _ in }
                pluginStore.destinationReadyCallbacks.append(callback)
                
                then("all state should be consistent") {
                    XCTAssertFalse(pluginStore.isStandardIntegration)
                    XCTAssertTrue(pluginStore.isDestinationReady)
                    XCTAssertEqual(pluginStore.destinationReadyCallbacks.count, 1)
                    XCTAssertNotNil(pluginStore.analytics)
                    XCTAssertNotNil(pluginStore.pluginChain)
                }
            }
        }
    }
}
