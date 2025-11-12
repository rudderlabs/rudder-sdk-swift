//
//  TrackEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 18/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("TrackEvent Tests")
struct TrackEventTests {
    
    @Test("given a track event with default values, when serialized, then matches expected JSON")
    func testDefaultTrackEvent() {
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "track_with_default_arguments")?.trimmed else {
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a track event with properties, when serialized, then matches expected JSON")
    func testTrackEventProperties() {
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "track_with_properties")?.trimmed else {
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a track event with options, when serialized, then matches expected JSON")
    func testTrackEventOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
        
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "track_with_options")?.trimmed else {
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a track event with properties and options, when serialized, then matches expected JSON")
    func testTrackEventPropertiesOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
        
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "track_with_properties_options")?.trimmed else {
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
}
