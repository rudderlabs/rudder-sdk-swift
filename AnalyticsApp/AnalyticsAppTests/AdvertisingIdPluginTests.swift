//
//  AdvertisingIdPluginTests.swift
//  AnalyticsAppTests
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Testing
import Analytics
@testable import AnalyticsApp

struct AdvertisingIdPluginTests {
    
    @Test
    func test_checkAdvertisingId_whenAuthorized() {
        given("Prepare the environment when authorized..") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let plugin = AdvertisingIdPlugin()
            analytics.addPlugin(plugin)
            
            let mockIdfa = "mock_idfa_1234"
            let event = MockEvent()
            
            plugin.trackingAuthorizationStatus = { .authorized }
            plugin.getAdvertisingId = { mockIdfa }
            
            when("execute the plugin..") {
                let result = plugin.execute(event: event)
                
                then("check the result..") {
                    #expect(result != nil)
                    guard let deviceContent = result?.context?["device"]?.value as? [String: Any],
                          let idfa = deviceContent["advertisingId"] as? String else { #expect(1 == 0, "advertisingId not found.."); return}
                    #expect(idfa == mockIdfa)
                }
            }
        }
    }
    
    @Test
    func test_checkAdvertisingId_whenDenied() {
        given("Prepare the environment when denied..") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let plugin = AdvertisingIdPlugin()
            analytics.addPlugin(plugin)
            
            let mockIdfa = "mock_idfa_1234"
            var event = MockEvent()
            if let modified = event.addToContext(info: ["device": ["sample_key": "sample_value"]]) as? MockEvent {
                event = modified
            }
            
            plugin.trackingAuthorizationStatus = { .denied }
            plugin.getAdvertisingId = { mockIdfa }
            
            when("execute the plugin..") {
                let result = plugin.execute(event: event)
                
                then("check the result..") {
                    #expect(result != nil)
                    guard let deviceContent = result?.context?["device"]?.value as? [String: Any] else { #expect(1 == 0, "deviceContent not found.."); return}
                    #expect(deviceContent["advertisingId"] == nil)
                }
            }
        }
    }
}
