//
//  BluetoothInfoPluginTests.swift
//  AnalyticsAppTests
//
//  Created by Satheesh Kannan on 17/02/25.
//

import Testing
import Analytics
@testable import AnalyticsApp

struct BluetoothInfoPluginTests {
    
    @Test
    func test_bluetoothAvailability_whenAuthorized() {
        given("a BluetoothInfoPlugin with authorized Bluetooth status") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let bluetoothInfoPlugin = BluetoothInfoPlugin()
            analytics.addPlugin(bluetoothInfoPlugin)
            
            bluetoothInfoPlugin.bluetoothAuthorizationStatus = { .allowedAlways }
            let event = MockEvent()
            
            when("the plugin intercepts the mock event") {
                let result = bluetoothInfoPlugin.intercept(event: event)
                
                then("it should inject bluetooth: true into the network context") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")
                    
                    guard let contextDict = result?.context?.rawDictionary,
                          let networkContext = contextDict["network"] as? [String: Any],
                          let isBluetoothAvailable = networkContext["bluetooth"] as? Bool else {
                        #expect(Bool(false), "Expected bluetooth status in network context")
                        return
                    }

                    #expect(isBluetoothAvailable == true, "Expected bluetooth to be true")
                }
            }
        }
    }
    
    @Test
    func test_bluetoothAvailability_whenDenied() {
        given("a BluetoothInfoPlugin with denied Bluetooth authorization") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let bluetoothInfoPlugin = BluetoothInfoPlugin()
            analytics.addPlugin(bluetoothInfoPlugin)
            
            bluetoothInfoPlugin.bluetoothAuthorizationStatus = { .denied }
            let event = MockEvent()
            
            when("the plugin intercepts the mock event") {
                let result = bluetoothInfoPlugin.intercept(event: event)
                
                then("it should NOT inject bluetooth status into the network context") {
                    #expect(result != nil, "Expected intercepted event to be non-nil")
                    
                    let networkContext = result?.context?.rawDictionary["network"]
                    #expect(networkContext == nil, "Expected no network context when Bluetooth is denied")
                }
            }
        }
    }
}
