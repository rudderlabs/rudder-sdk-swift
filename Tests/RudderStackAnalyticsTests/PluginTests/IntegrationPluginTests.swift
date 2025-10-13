//
//  IntegrationPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import XCTest
@testable import RudderStackAnalytics

final class IntegrationPluginTests: XCTestCase {
    
    var analytics: Analytics!
    var mockPlugin: MockIntegrationPlugin!
    var standardPlugin: MockStandardIntegrationPlugin!
    
    override func setUp() {
        super.setUp()
        analytics = MockProvider.clientWithDiskStorage
        mockPlugin = MockIntegrationPlugin(key: "test_destination")
        standardPlugin = MockStandardIntegrationPlugin(key: "standard_destination")
        
        // Setup plugins with analytics
        mockPlugin.setup(analytics: analytics)
        standardPlugin.setup(analytics: analytics)
    }
    
    override func tearDown() {
        mockPlugin = nil
        standardPlugin = nil
        analytics = nil
        super.tearDown()
    }
    
    // MARK: - Basic Protocol Tests
    
    func test_plugin_properties() {
        given("A mock integration plugin") {
            when("plugin properties are accessed") {
                then("plugin should have correct type and key") {
                    XCTAssertEqual(mockPlugin.pluginType, .terminal)
                    XCTAssertEqual(mockPlugin.key, "test_destination")
                    XCTAssertTrue(mockPlugin.analytics === analytics)
                }
            }
        }
    }
    
    func test_getDestinationInstance_whenNotCreated() {
        given("A plugin without created destination") {
            when("getDestinationInstance is called") {
                let instance = mockPlugin.getDestinationInstance()
                
                then("instance should be nil and method should be tracked") {
                    XCTAssertNil(instance)
                    XCTAssertTrue(mockPlugin.getDestinationInstanceCalled)
                }
            }
        }
    }
    
    func test_getDestinationInstance_whenCreated() {
        given("A plugin with created destination") {
            let config = ["apiKey": "test_key"]
            
            when("destination is created and getDestinationInstance is called") {
                try! mockPlugin.create(destinationConfig: config)
                let instance = mockPlugin.getDestinationInstance()
                
                then("instance should not be nil") {
                    XCTAssertNotNil(instance)
                    XCTAssertTrue(mockPlugin.getDestinationInstanceCalled)
                    XCTAssertTrue(instance is MockDestination)
                }
            }
        }
    }
    
    // MARK: - Create Method Tests
    
    func test_create_success() {
        given("A plugin and valid configuration") {
            let config = ["apiKey": "test_key", "enabled": true] as [String: Any]
            
            when("create is called") {
                try! mockPlugin.create(destinationConfig: config)
                
                then("destination should be created successfully") {
                    XCTAssertTrue(mockPlugin.createCalled)
                    XCTAssertNotNil(mockPlugin.lastDestinationConfig)
                    XCTAssertEqual(mockPlugin.lastDestinationConfig?["apiKey"] as? String, "test_key")
                    XCTAssertNotNil(mockPlugin.getDestinationInstance())
                }
            }
        }
    }
    
    func test_create_method_error_handling() {
        given("A plugin with createThrowsError set") {
            let mockPlugin = MockIntegrationPlugin(key: "test_key")
            let config = ["apiKey": "test_key"]
            mockPlugin.createThrowsError = MockIntegrationError.createFailed
            
            when("create is called") {
                do {
                    try mockPlugin.create(destinationConfig: config)
                    XCTFail("Expected error to be thrown")
                } catch {
                    then("error should be createFailed") {
                        XCTAssertTrue(error is MockIntegrationError)
                        XCTAssertEqual(error as? MockIntegrationError, .createFailed)
                    }
                }
            }
        }
    }
    
    // MARK: - Update Method Tests
    
    func test_update_success() {
        given("A plugin with created destination") {
            let initialConfig = ["apiKey": "test_key"]
            let updatedConfig = ["apiKey": "updated_key", "timeout": 30] as [String: Any]
            
            when("update is called") {
                try! mockPlugin.create(destinationConfig: initialConfig)
                try! mockPlugin.update(destinationConfig: updatedConfig)
                
                then("destination should be updated successfully") {
                    XCTAssertTrue(mockPlugin.updateCalled)
                    XCTAssertEqual(mockPlugin.lastDestinationConfig?["apiKey"] as? String, "updated_key")
                    XCTAssertEqual(mockPlugin.lastDestinationConfig?["timeout"] as? Int, 30)
                }
            }
        }
    }
    
    func test_update_failure() {
        given("A plugin configured to throw error on update") {
            let config = ["apiKey": "test_key"]
            mockPlugin.updateThrowsError = MockIntegrationError.updateFailed
            
            when("update is called") {
                do {
                    try mockPlugin.update(destinationConfig: config)
                    XCTFail("Expected error to be thrown")
                } catch {
                    XCTAssertTrue(error is MockIntegrationError)
                    XCTAssertEqual(error as? MockIntegrationError, .updateFailed)
                }
                
                then("update should be tracked") {
                    XCTAssertTrue(mockPlugin.updateCalled)
                }
            }
        }
    }
    
    // MARK: - Flush and Reset Tests
    
    func test_flush() {
        given("A plugin") {
            when("flush is called") {
                mockPlugin.flush()
                
                then("flush should be tracked") {
                    XCTAssertTrue(mockPlugin.flushCalled)
                }
            }
        }
    }
    
    func test_reset() {
        given("A plugin with created destination") {
            let config = ["apiKey": "test_key"]
            
            when("reset is called") {
                try! mockPlugin.create(destinationConfig: config)
                XCTAssertNotNil(mockPlugin.getDestinationInstance())
                
                mockPlugin.reset()
                
                then("reset should be tracked and destination cleared") {
                    XCTAssertTrue(mockPlugin.resetCalled)
                    XCTAssertNil(mockPlugin.getDestinationInstance())
                }
            }
        }
    }
    
    // MARK: - Event Handling Tests
    
    func test_identify_event_handling() {
        given("A plugin and identify event") {
            let identifyEvent = IdentifyEvent()
            
            when("identify is called") {
                mockPlugin.identify(payload: identifyEvent)
                
                then("event should be received and stored") {
                    XCTAssertNotNil(mockPlugin.identifyEventReceived)
                }
            }
        }
    }
    
    func test_track_event_handling() {
        given("A plugin and track event") {
            let trackEvent = TrackEvent(event: "Button Clicked")
            
            when("track is called") {
                mockPlugin.track(payload: trackEvent)
                
                then("event should be received and stored") {
                    XCTAssertNotNil(mockPlugin.trackEventReceived)
                    XCTAssertEqual(mockPlugin.trackEventReceived?.event, "Button Clicked")
                }
            }
        }
    }
    
    func test_screen_event_handling() {
        given("A plugin and screen event") {
            let screenEvent = ScreenEvent(screenName: "Test Screen")
            
            when("screen is called") {
                mockPlugin.screen(payload: screenEvent)
                
                then("event should be received and stored") {
                    XCTAssertNotNil(mockPlugin.screenEventReceived)
                }
            }
        }
    }
    
    func test_group_event_handling() {
        given("A plugin and group event") {
            let groupEvent = GroupEvent(groupId: "group123")
            
            when("group is called") {
                mockPlugin.group(payload: groupEvent)
                
                then("event should be received and stored") {
                    XCTAssertNotNil(mockPlugin.groupEventReceived)
                    XCTAssertEqual(mockPlugin.groupEventReceived?.groupId, "group123")
                }
            }
        }
    }
    
    func test_alias_event_handling() {
        given("A plugin and alias event") {
            let aliasEvent = AliasEvent(previousId: "old_id", userIdentity: UserIdentity(userId: "new_id"))
            
            when("alias is called") {
                mockPlugin.alias(payload: aliasEvent)
                
                then("event should be received and stored") {
                    XCTAssertNotNil(mockPlugin.aliasEventReceived)
                }
            }
        }
    }
    
    // MARK: - Integration with Analytics Tests
    
    func test_pluginStore_access() {
        given("A plugin setup with analytics that has integration manager") {
            // Create a plugin store for this plugin
            let pluginStore = IntegrationPluginStore(analytics: analytics)
            analytics.integrationManager.integrationPluginStores[mockPlugin.key] = pluginStore
            
            when("pluginStore is accessed") {
                let store = mockPlugin.pluginStore
                
                then("store should be accessible") {
                    XCTAssertNotNil(store)
                    XCTAssertTrue(store === pluginStore)
                }
            }
        }
    }
    
    func test_pluginChain_access() {
        given("A plugin with plugin store") {
            let pluginStore = IntegrationPluginStore(analytics: analytics)
            analytics.integrationManager.integrationPluginStores[mockPlugin.key] = pluginStore
            
            when("pluginChain is accessed") {
                let chain = mockPlugin.pluginChain
                
                then("chain should be accessible from store") {
                    XCTAssertNotNil(chain)
                    XCTAssertTrue(chain === pluginStore.pluginChain)
                }
            }
        }
    }
    
    // MARK: - StandardPlugin Tests
    
    func test_standardPlugin_conformance() {
        given("A standard integration plugin") {
            when("plugin is checked for StandardPlugin conformance") {
                then("plugin should conform to StandardPlugin") {
                    XCTAssertNotNil(standardPlugin)
                }
            }
        }
    }
    
    // MARK: - onDestinationReady Tests
    
    func test_onDestinationReady_when_destination_not_ready() {
        given("A plugin without destination ready") {
            var callbackCalled = false
            
            when("onDestinationReady is called") {
                mockPlugin.onDestinationReady { instance, result in
                    callbackCalled = true
                    _ = instance
                    _ = result
                }
                
                then("callback should be stored for later execution") {
                    // Since destination is not ready, callback should be stored
                    XCTAssertFalse(callbackCalled)
                    // Note: Testing internal state would require access to plugin store
                }
            }
        }
    }
    
    func test_onDestinationReady_when_destination_ready_with_instance() {
        given("A plugin with ready destination") {
            var callbackCalled = false
            var receivedInstance: Any?
            var receivedResult: DestinationResult?
            
            let config = ["apiKey": "test_key"]
            try! mockPlugin.create(destinationConfig: config)
            
            // Setup plugin store as ready
            let pluginStore = IntegrationPluginStore(analytics: analytics)
            pluginStore.isDestinationReady = true
            analytics.integrationManager.integrationPluginStores[mockPlugin.key] = pluginStore
            
            when("onDestinationReady is called") {
                mockPlugin.onDestinationReady { instance, result in
                    callbackCalled = true
                    receivedInstance = instance
                    receivedResult = result
                }
                
                then("callback should be called immediately with success") {
                    XCTAssertTrue(callbackCalled)
                    XCTAssertNotNil(receivedInstance)
                    
                    switch receivedResult {
                    case .success:
                        XCTAssertTrue(true) // Success case
                    case .failure, .none:
                        XCTFail("Expected success result")
                    }
                }
            }
        }
    }
}
