//
//  AliasEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 01/02/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("AliasEvent Tests")
struct AliasEventTests {
    
    @Test("given an alias event with default values, when serialized, then matches expected JSON")
    func defaultAliasEvent() {
        var event: Event = AliasEvent(previousId: "test_previous_id", userIdentity: UserIdentity(userId: "test_user_id"))
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "alias_with_default_arguments")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
    
    @Test("given an alias event with options, when serialized, then matches expected JSON")
    func aliasEventOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
        
        var event: Event = AliasEvent(previousId: "test_previous_id", options: option, userIdentity: UserIdentity(userId: "test_user_id"))
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("Failed to serialize the event.")
            return 
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "alias_with_options")?.trimmed else { 
            Issue.record("Failed to read the expected JSON.")
            return 
        }
        
        #expect(json == expected)
    }
}
