//
//  DynamicUserAgentPluginTests.swift
//  SwiftUIExampleAppTests
//
//  Created by Satheesh Kannan on 05/09/25.
//

import Testing
import RudderStackAnalytics
@testable import SwiftUIExampleApp

struct DynamicUserAgentPluginTests {
    
    @Test
    func userAgent_isInjected_whenUserAgentIsAvailable() {
        given("a UserAgentPlugin with userAgent set and event with no userAgent context") {
            let plugin = DynamicUserAgentPlugin()
            let event = MockEvent()
            
            // Directly set userAgent to test the intercept logic
            plugin.userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
            
            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should inject the user agent into the context") {
                    guard let contextDict = result?.context?.rawDictionary,
                          let userAgent = contextDict["userAgent"] as? String else {
                        #expect(Bool(false), "Expected userAgent to exist in context")
                        return
                    }
                    #expect(!userAgent.isEmpty, "Expected userAgent to not be empty")
                    #expect(userAgent.contains("Mozilla/5.0"), "Expected userAgent to contain Mozilla/5.0")
                    #expect(userAgent.contains("iPhone"), "Expected userAgent to contain iPhone")
                }
            }
        }
    }

    @Test
    func userAgent_replacesExistingUserAgent_inContext() {
        given("a UserAgentPlugin with userAgent set and event with existing userAgent") {
            let plugin = DynamicUserAgentPlugin()
            let event = MockEvent()
            let newUserAgent = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
            
            plugin.userAgent = newUserAgent
            event.context = [
                "userAgent": "old-user-agent",
                "app": ["name": "TestApp"]
            ].codableWrapped
            
            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should replace the existing userAgent and preserve other fields") {
                    guard let contextDict = result?.context?.rawDictionary else {
                        #expect(Bool(false), "Expected context to exist")
                        return
                    }
                    
                    let userAgent = contextDict["userAgent"] as? String
                    #expect(userAgent == newUserAgent, "Expected userAgent to be replaced with new value")
                    #expect(userAgent != "old-user-agent", "Expected userAgent to not be the old value")
                    
                    let appContext = contextDict["app"] as? [String: Any]
                    #expect(appContext?["name"] as? String == "TestApp", "Expected app context to be preserved")
                }
            }
        }
    }

    @Test
    func userAgent_returnsOriginalEvent_whenUserAgentNotAvailable() {
        given("a UserAgentPlugin with no userAgent available") {
            let plugin = DynamicUserAgentPlugin()
            let event = MockEvent()
            event.context = [
                "app": ["name": "TestApp"]
            ].codableWrapped
            // Ensure userAgent is nil (it starts as nil anyway)
            plugin.userAgent = nil

            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should return the original event unchanged") {
                    guard let contextDict = result?.context?.rawDictionary else {
                        #expect(Bool(false), "Expected the same event instance to be returned")
                        return
                    }
                    
                    // Verify no userAgent was added to context
                    let userAgent = contextDict["userAgent"]
                    #expect(userAgent == nil, "Expected no userAgent to be added when userAgent is nil")
                }
            }
        }
    }
    
    @Test
    func userAgent_preservesOtherContextFields_whenAdding() {
        given("a UserAgentPlugin and event with existing context fields") {
            let plugin = DynamicUserAgentPlugin()
            let event = MockEvent()
            
            plugin.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
            event.context = [
                "device": ["model": "iPhone", "id": "device123"],
                "app": ["name": "TestApp", "version": "1.0"],
                "library": ["name": "RudderStack", "version": "2.0"]
            ].codableWrapped
            
            when("the plugin intercepts the event") {
                let result = plugin.intercept(event: event)

                then("it should add userAgent and preserve all existing context fields") {
                    guard let contextDict = result?.context?.rawDictionary else {
                        #expect(Bool(false), "Expected context to exist")
                        return
                    }
                    
                    // Check userAgent was added
                    let userAgent = contextDict["userAgent"] as? String
                    #expect(userAgent?.contains("Mozilla/5.0") == true, "Expected userAgent to be added")
                    
                    // Check existing fields are preserved
                    let deviceContext = contextDict["device"] as? [String: Any]
                    #expect(deviceContext?["model"] as? String == "iPhone", "Expected device model to be preserved")
                    #expect(deviceContext?["id"] as? String == "device123", "Expected device id to be preserved")
                    
                    let appContext = contextDict["app"] as? [String: Any]
                    #expect(appContext?["name"] as? String == "TestApp", "Expected app name to be preserved")
                    #expect(appContext?["version"] as? String == "1.0", "Expected app version to be preserved")
                    
                    let libraryContext = contextDict["library"] as? [String: Any]
                    #expect(libraryContext?["name"] as? String == "RudderStack", "Expected library name to be preserved")
                    #expect(libraryContext?["version"] as? String == "2.0", "Expected library version to be preserved")
                }
            }
        }
    }
    
   @Test @MainActor
   func readUserAgent_returnsNonEmptyString() async {
       let plugin = DynamicUserAgentPlugin()
       guard let userAgent = await plugin.readUserAgent() else {
           #expect(Bool(false), "Expected userAgent to not be nil")
           return
       }
       
       #expect(!userAgent.isEmpty, "Expected userAgent to not be empty")
       #expect(userAgent.contains("Mozilla/5.0"), "Expected userAgent to contain Mozilla/5.0")
       #expect(userAgent.contains("AppleWebKit"), "Expected userAgent to contain AppleWebKit")
   }
}



