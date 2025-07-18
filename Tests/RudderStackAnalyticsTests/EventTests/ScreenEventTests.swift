//
//  ScreenEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 20/11/24.
//

import XCTest
@testable import RudderStackAnalytics

final class ScreenEventTests: XCTestCase {
    
    func test_defaultScreenEvent() {
        given("A screen event with default values..") {
            var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }

                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "screen_with_default_arguments")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_screenEvent_category() {
        given("A screen event with category value..") {
            var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, category: "Main")
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "screen_with_category")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_screenEvent_properties() {
        given("A screen event with property values..") {
            var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, properties: MockProvider.sampleEventproperties)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "screen_with_properties")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_screenEvent_options() {
        given("A screen event with options..") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
            
            var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }

                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "screen_with_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_screenEvent_category_properties_options() {
        given("A screen event with all values...") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
            
            var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, category: "Main", properties: MockProvider.sampleEventproperties, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "screen_with_all_values")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
}
