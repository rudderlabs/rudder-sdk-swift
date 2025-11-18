//
//  EventFilteringPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 21/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

struct EventFilteringPluginTests {
    
    private let destinationKey = "TestDestination"
    
    private func createAnalytics() -> Analytics {
        let configuration = Configuration(writeKey: "test-write-key", dataPlaneUrl: "https://test.rudderstack.com")
        return Analytics(configuration: configuration)
    }
    
    private func createPlugin() -> EventFilteringPlugin {
        return EventFilteringPlugin(key: destinationKey)
    }
    
    // MARK: - Plugin Setup Tests
    
    @Test("Given an EventFilteringPlugin, When created, Then plugin type should be preProcess")
    func testPluginType() {
        let plugin = createPlugin()
        #expect(plugin.pluginType == .preProcess)
    }
    
    @Test("Given an EventFilteringPlugin, When setup is called, Then analytics should be set")
    func testSetup() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        #expect(plugin.analytics != nil)
    }
    
    // MARK: - Event Filtering Tests - No Configuration
    
    @Test("Given an EventFilteringPlugin with no configuration, When intercepting a track event, Then event should pass through unchanged")
    func testInterceptWithNoConfiguration() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        let trackEvent = TrackEvent(event: "Test Event")
        
        let result = plugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result is TrackEvent)
        if let resultTrack = result as? TrackEvent {
            #expect(resultTrack.event == "Test Event")
        }
    }
    
    @Test("Given an EventFilteringPlugin, When intercepting a non-track event, Then event should always pass through")
    func testInterceptWithNonTrackEvent() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        let identifyEvent = IdentifyEvent()
        
        let result = plugin.intercept(event: identifyEvent)
        
        #expect(result != nil)
        #expect(result is IdentifyEvent)
    }
    
    // MARK: - Whitelist Configuration Tests
    
    @Test("Given an EventFilteringPlugin with whitelist configuration, When intercepting a whitelisted event, Then event should pass through")
    func testInterceptWithWhitelistAllowedEvent() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Product Purchased"],
                ["eventName": "User Registered"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let allowedEvent = TrackEvent(event: "Product Purchased")
        let result = plugin.intercept(event: allowedEvent)
        
        #expect(result != nil)
        if let resultTrack = result as? TrackEvent {
            #expect(resultTrack.event == "Product Purchased")
        }
    }
    
    @Test("Given an EventFilteringPlugin with whitelist configuration, When intercepting a non-whitelisted event, Then event should be filtered out")
    func testInterceptWithWhitelistBlockedEvent() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Product Purchased"],
                ["eventName": "User Registered"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let blockedEvent = TrackEvent(event: "Random Event")
        let result = plugin.intercept(event: blockedEvent)
        
        #expect(result == nil)
    }
    
    // MARK: - Blacklist Configuration Tests
    
    @Test("Given an EventFilteringPlugin with blacklist configuration, When intercepting a blacklisted event, Then event should be filtered out")
    func testInterceptWithBlacklistBlockedEvent() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "blacklistedEvents",
            "blacklistedEvents": [
                ["eventName": "Application Opened"],
                ["eventName": "Application Backgrounded"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let blockedEvent = TrackEvent(event: "Application Opened")
        let result = plugin.intercept(event: blockedEvent)
        
        #expect(result == nil)
    }
    
    @Test("Given an EventFilteringPlugin with blacklist configuration, When intercepting a non-blacklisted event, Then event should pass through")
    func testInterceptWithBlacklistAllowedEvent() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "blacklistedEvents",
            "blacklistedEvents": [
                ["eventName": "Application Opened"],
                ["eventName": "Application Backgrounded"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let allowedEvent = TrackEvent(event: "Product Purchased")
        let result = plugin.intercept(event: allowedEvent)
        
        #expect(result != nil)
        if let resultTrack = result as? TrackEvent {
            #expect(resultTrack.event == "Product Purchased")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Given an EventFilteringPlugin with configuration, When intercepting an event with empty name, Then event should be filtered out")
    func testInterceptWithEmptyEventName() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Valid Event"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let emptyEvent = TrackEvent(event: "")
        let result = plugin.intercept(event: emptyEvent)
        
        #expect(result == nil)
    }
    
    @Test("Given an EventFilteringPlugin with configuration, When intercepting an event with whitespace, Then event should pass through after trimming")
    func testInterceptWithWhitespaceEventName() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Valid Event"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let whitespaceEvent = TrackEvent(event: "  Valid Event  ")
        let result = plugin.intercept(event: whitespaceEvent)
        
        #expect(result != nil)
        if let resultTrack = result as? TrackEvent {
            #expect(resultTrack.event == "  Valid Event  ")
        }
    }
    
    @Test("Given an EventFilteringPlugin, When updating with malformed configuration, Then plugin should handle gracefully and allow all events")
    func testUpdateConfigurationWithMalformedData() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let malformedConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": "invalid_format"
        ]
        
        plugin.updateConfiguration(destinationConfig: malformedConfig)
        
        let testEvent = TrackEvent(event: "Test Event")
        let result = plugin.intercept(event: testEvent)
        
        #expect(result != nil)
    }
    
    @Test("Given an EventFilteringPlugin, When updating with configuration containing invalid entries, Then only valid events should be processed correctly")
    func testUpdateConfigurationWithMissingEventName() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let configWithMissingNames: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Valid Event"],
                ["invalidKey": "Invalid Entry"],
                ["eventName": ""]
            ]
        ]
        
        plugin.updateConfiguration(destinationConfig: configWithMissingNames)
        
        let validEvent = TrackEvent(event: "Valid Event")
        let invalidEvent = TrackEvent(event: "Invalid Entry")
        
        let validResult = plugin.intercept(event: validEvent)
        let invalidResult = plugin.intercept(event: invalidEvent)
        
        #expect(validResult != nil)
        #expect(invalidResult == nil)
    }
    
    @Test("Given an EventFilteringPlugin with configuration, When plugin is deallocated, Then new plugin instance allows all events through")
    func testDeinitClearsConfiguration() {
        let analytics = createAnalytics()
        
        // Create a plugin with filtering configuration
        do {
            let plugin = createPlugin()
            plugin.setup(analytics: analytics)
            
            let destinationConfig: [String: Any] = [
                "eventFilteringOption": "whitelistedEvents",
                "whitelistedEvents": [
                    ["eventName": "Test Event"]
                ]
            ]
            plugin.updateConfiguration(destinationConfig: destinationConfig)
            
            // Verify filtering is working
            let blockedEvent = TrackEvent(event: "Blocked Event")
            let blockedResult = plugin.intercept(event: blockedEvent)
            #expect(blockedResult == nil)
            
            // Plugin goes out of scope here and deinit is called
        }
        
        // Create a new plugin instance to verify clean state
        let newPlugin = createPlugin()
        newPlugin.setup(analytics: analytics)
        
        let testEvent = TrackEvent(event: "Test Event")
        let result = newPlugin.intercept(event: testEvent)
        
        #expect(result != nil)
    }
    
    @Test("Given an EventFilteringPlugin with source config listener, When source configuration is updated, Then filtering configuration should be updated automatically")
    func testSourceConfigurationListener() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        // Initially no filtering should be applied
        let initialEvent = TrackEvent(event: "Test Event")
        let initialResult = plugin.intercept(event: initialEvent)
        #expect(initialResult != nil)
        
        // Create a mock source configuration with destination config
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "whitelistedEvents",
            "whitelistedEvents": [
                ["eventName": "Allowed Event"]
            ]
        ]
        
        // Simulate source configuration update via the public interface
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        // Now filtering should be applied
        let allowedEvent = TrackEvent(event: "Allowed Event")
        let blockedEvent = TrackEvent(event: "Blocked Event")
        
        let allowedResult = plugin.intercept(event: allowedEvent)
        let blockedResult = plugin.intercept(event: blockedEvent)
        
        #expect(allowedResult != nil)
        #expect(blockedResult == nil)
    }
    
    @Test("Given an EventFilteringPlugin with blacklist configuration, When intercepting multiple events, Then blocked events should be nil and allowed events should pass through")
    func testInterceptWithMultipleEvents() {
        let analytics = createAnalytics()
        let plugin = createPlugin()
        plugin.setup(analytics: analytics)
        
        let destinationConfig: [String: Any] = [
            "eventFilteringOption": "blacklistedEvents",
            "blacklistedEvents": [
                ["eventName": "Blocked Event 1"],
                ["eventName": "Blocked Event 2"]
            ]
        ]
        plugin.updateConfiguration(destinationConfig: destinationConfig)
        
        let events = [
            TrackEvent(event: "Blocked Event 1"),
            TrackEvent(event: "Allowed Event"),
            TrackEvent(event: "Blocked Event 2"),
            TrackEvent(event: "Another Allowed Event")
        ]
        
        let results = events.map { plugin.intercept(event: $0) }
        
        #expect(results[0] == nil)
        #expect(results[1] != nil)
        #expect(results[2] == nil)
        #expect(results[3] != nil)
    }
}
