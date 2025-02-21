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
        given("Prepare the environment when authorization is authorized...") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let bluetoothInfoPlugin = BluetoothInfoPlugin()
            analytics.addPlugin(bluetoothInfoPlugin)
            
            let event = MockEvent()
            
            bluetoothInfoPlugin.bluetoothAuthorizationStatus = { .allowedAlways }
            
            when("intercept the plugin using mock event..") {
                let result = bluetoothInfoPlugin.intercept(event: event)
                
                then("check the result if bluetooth status added or not..") {
                    #expect(result != nil)
                    
                    guard let networkContext = result?.context?["network"]?.value as? [String: Any], let isBluetoothAvailable = networkContext["bluetooth"] as? Bool else {
                        #expect(1 == 0, "bluetooth status not found.."); return
                    }
                    #expect(isBluetoothAvailable)
                }
            }
        }
    }
    
    @Test
    func test_bluetoothAvailability_whenDenied() {
        given("Prepare the environment when authorization is denied..") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let bluetoothInfoPlugin = BluetoothInfoPlugin()
            analytics.addPlugin(bluetoothInfoPlugin)
            
            let event = MockEvent()
            
            bluetoothInfoPlugin.bluetoothAuthorizationStatus = { .denied }
            
            when("intercept the plugin using mock event..") {
                let result = bluetoothInfoPlugin.intercept(event: event)
                
                then("check the result if bluetooth status added or not..") {
                    #expect(result != nil)
                    #expect(result?.context?["network"] == nil, "bluetooth status not found..")
                }
            }
        }
    }
}
