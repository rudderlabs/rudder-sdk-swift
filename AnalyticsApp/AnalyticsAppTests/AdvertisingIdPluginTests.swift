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
    func test_advertisingId_isInjected_whenTrackingIsAuthorized() {
        given("an analytics client and AdvertisingIdPlugin with authorized tracking") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)
            
            let advertisingIdPlugin = AdvertisingIdPlugin()
            analytics.addPlugin(advertisingIdPlugin)
            
            let mockIdfa = "mock_idfa_1234"
            advertisingIdPlugin.trackingAuthorizationStatus = { .authorized }
            advertisingIdPlugin.getAdvertisingId = { mockIdfa }
            
            let event = MockEvent()
            
            when("the plugin intercepts the event") {
                let result = advertisingIdPlugin.intercept(event: event)
                
                then("it should inject the advertisingId into the device context") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")
                    
                    guard let contextDict = result?.context?.rawDictionary,
                          let deviceContext = contextDict["device"] as? [String: Any] else {
                        #expect(1 == 0, "Expected device context to exist")
                        return
                    }
                    
                    #expect(deviceContext["advertisingId"] as? String == mockIdfa, "Expected advertisingId to match mock value")
                    #expect(deviceContext["adTrackingEnabled"] as? Bool == true, "Expected adTrackingEnabled to be true")
                }
            }
        }
    }
    
    @Test
    func test_advertisingId_isNotInjected_whenTrackingIsDenied() {
        given("an AdvertisingIdPlugin with denied tracking and an event with existing device context") {
            let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
            let analytics = AnalyticsClient(configuration: config)

            let advertisingIdPlugin = AdvertisingIdPlugin()
            analytics.addPlugin(advertisingIdPlugin)

            let mockIdfa = "mock_idfa_1234"
            advertisingIdPlugin.trackingAuthorizationStatus = { .denied }
            advertisingIdPlugin.getAdvertisingId = { mockIdfa }

            // Create an event with existing device context
            let event = MockEvent()
            event.context = [
                "device": [
                    "sample_key": "sample_value"
                ]
            ].codableWrapped

            when("the plugin intercepts the event") {
                let result = advertisingIdPlugin.intercept(event: event)

                then("it should not add the advertisingId but should preserve existing device context") {
                    #expect(result != nil, "Expected the intercepted event to be non-nil")

                    guard let contextDict = result?.context?.rawDictionary,
                          let deviceContext = contextDict["device"] as? [String: Any] else {
                        #expect(Bool(false), "Expected device context to exist")
                        return
                    }

                    #expect(deviceContext["advertisingId"] == nil, "Expected advertisingId to be absent when tracking is denied")
                    #expect(deviceContext["sample_key"] as? String == "sample_value", "Expected original device context to be preserved")
                }
            }
        }
    }
}
