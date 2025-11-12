//
//  GroupEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 20/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("GroupEvent Tests")
struct GroupEventTests {
    
    @Test("given a group event with default values, when serialized, then matches expected JSON")
    func testDefaultGroupEvent() {
        var event: Event = GroupEvent(groupId: MockProvider.SampleEventName.group)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "group_with_default_arguments")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a group event with traits, when serialized, then matches expected JSON")
    func testGroupEventTraits() {
        var event: Event = GroupEvent(groupId: MockProvider.SampleEventName.group, traits: MockProvider.sampleEventproperties)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "group_with_traits")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a group event with options, when serialized, then matches expected JSON")
    func testGroupEventOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
        
        var event: Event = GroupEvent(groupId: MockProvider.SampleEventName.group, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "group_with_options")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given a group event with traits and options, when serialized, then matches expected JSON")
    func testGroupEventTraitsOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
        
        var event: Event = GroupEvent(groupId: MockProvider.SampleEventName.group, traits: MockProvider.sampleEventproperties, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "group_with_all_values")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
}
