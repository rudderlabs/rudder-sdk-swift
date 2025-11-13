//
//  IntegrationOptionsPluginTests.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 23/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

private let mockDestinationKey = "MockDestination"

struct IntegrationOptionsPluginTests {
    
    var analytics: Analytics
    
    init() {
        let mockConfiguration = MockProvider.createMockConfiguration()
        mockConfiguration.flushPolicies = []
        
        self.analytics = Analytics(configuration: mockConfiguration)
    }
    
    @Test("Event with all destinations enabled returns event")
    func eventWithAllDestinationsEnabled() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = ["All": AnyCodable(true)]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Event with destination disabled returns nil")
    func eventWithDestinationDisabled() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [mockDestinationKey: AnyCodable(false)]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result == nil)
    }
    
    @Test("Event with all destinations disabled returns nil")
    func eventWithAllDestinationsDisabled() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = ["All": AnyCodable(false)]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result == nil)
    }
    
    @Test("Event with all disabled but destination enabled returns event")
    func eventWithAllDisabledButDestinationEnabled() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [
            "All": AnyCodable(false),
            mockDestinationKey: AnyCodable(true)
        ]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Plugin for different destination ignores mock destination")
    func pluginForDifferentDestination() {
        let plugin = IntegrationOptionsPlugin(key: "SomeOtherDestination")
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [
            "All": AnyCodable(true),
            mockDestinationKey: AnyCodable(false)
        ]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Event with empty integrations returns event")
    func eventWithEmptyIntegrations() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [:]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Event with integration field set to string returns event")
    func eventWithIntegrationFieldAsString() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [mockDestinationKey: AnyCodable("some string value")]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Event with integration field set to complex object returns event")
    func eventWithIntegrationFieldAsComplexObject() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        var eventWithIntegrations = event
        eventWithIntegrations.integrations = [
            mockDestinationKey: AnyCodable(["key": "value"])
        ]
        
        let result = plugin.intercept(event: eventWithIntegrations)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
    
    @Test("Event with nil integrations returns event")
    func eventWithNilIntegrations() {
        let plugin = IntegrationOptionsPlugin(key: mockDestinationKey)
        plugin.setup(analytics: analytics)
        
        let event = TrackEvent(event: "event-name", properties: [:])
        
        let result = plugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.type == .track)
    }
}
