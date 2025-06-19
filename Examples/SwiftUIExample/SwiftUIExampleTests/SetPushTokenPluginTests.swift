//
//  SetPushTokenPluginTests.swift
//  SwiftUIExampleTests
//
//  Created by Satheesh Kannan on 11/06/25.
//

import Testing
import RudderStackAnalytics
@testable import SwiftUIExample

struct SetPushTokenPluginTests {

    @Test
    func pushToken_isInjected_whenNoDeviceContextExists() {
        given("a SetPushTokenPlugin and event with no device context") {
            let plugin = SetPushTokenPlugin(pushToken: "token_abc")
            let event = MockEvent()

            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should inject the push token into the device context") {
                    guard let contextDict = result?.context?.rawDictionary,
                          let deviceContext = contextDict["device"] as? [String: Any] else {
                        #expect(Bool(false), "Expected device context to exist")
                        return
                    }
                    #expect(deviceContext["token"] as? String == "token_abc", "Expected token to match")
                }
            }
        }
    }

    @Test
    func pushToken_replacesExistingToken_inDeviceContext() {
        given("a SetPushTokenPlugin and event with existing device token") {
            let plugin = SetPushTokenPlugin(pushToken: "new_token")
            let event = MockEvent()
            event.context = [
                "device": [
                    "token": "old_token",
                    "model": "iPhone"
                ]
            ].codableWrapped

            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should replace the existing token and preserve other fields") {
                    guard let contextDict = result?.context?.rawDictionary,
                          let deviceContext = contextDict["device"] as? [String: Any] else {
                        #expect(Bool(false), "Expected device context to exist")
                        return
                    }
                    #expect(deviceContext["token"] as? String == "new_token", "Expected token to be replaced")
                    #expect(deviceContext["model"] as? String == "iPhone", "Expected model to be preserved")
                }
            }
        }
    }

    @Test
    func pushToken_isAdded_whenDeviceContextExistsButNoToken() {
        given("a SetPushTokenPlugin and event with device context but no token") {
            let plugin = SetPushTokenPlugin(pushToken: "xyz789")
            let event = MockEvent()
            event.context = [
                "device": [
                    "model": "iPad"
                ]
            ].codableWrapped

            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should add the push token and preserve other fields") {
                    guard let contextDict = result?.context?.rawDictionary,
                          let deviceContext = contextDict["device"] as? [String: Any] else {
                        #expect(Bool(false), "Expected device context to exist")
                        return
                    }
                    #expect(deviceContext["token"] as? String == "xyz789", "Expected token to be added")
                    #expect(deviceContext["model"] as? String == "iPad", "Expected model to be preserved")
                }
            }
        }
    }
}
