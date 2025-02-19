//
//  GroupEventTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 20/11/24.
//

import XCTest
@testable import Analytics

final class GroupEventTests: XCTestCase {
    
    func test_defaultGroupEvent() {
        given("A group event with default values..") {
            var event: Message = GroupEvent(groupId: MockProvider.SampleEventName.group)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "group_with_default_arguments")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_groupEvent_traits() {
        given("A group event with trait values..") {
            var event: Message = GroupEvent(groupId: MockProvider.SampleEventName.group, traits: MockProvider.sampleEventproperties)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "group_with_traits")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_groupEvent_options() {
        given("A group event with options..") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
            
            var event: Message = GroupEvent(groupId: MockProvider.SampleEventName.group, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "group_with_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_groupEvent_traits_options() {
        given("A group event with all values..") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
            
            var event: Message = GroupEvent(groupId: MockProvider.SampleEventName.group, traits: MockProvider.sampleEventproperties, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "group_with_all_values")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
}
