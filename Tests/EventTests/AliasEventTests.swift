//
//  AliasEventTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 01/02/25.
//

import XCTest
@testable import Analytics

final class AliasEventTests: XCTestCase {
    
    func test_defaultAliasEvent() {
        given("A alias event with test userId provided without any options..") {
            var event: Event = AliasEvent(previousId: "test_previous_id", userIdentity: UserIdentity(userId: "test_user_id"))
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "alias_with_default_arguments")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_aliasEvent_options() {
        given("A alias event with test userId provided with any options..") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
            
            var event: Event = AliasEvent(previousId: "test_previous_id", options: option, userIdentity: UserIdentity(userId: "test_user_id"))
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "alias_with_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
}
