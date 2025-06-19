//
//  TrackEventTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/11/24.
//

import XCTest
@testable import RudderStackAnalytics

final class TrackEventTests: XCTestCase {
    
    func test_defaultTrackEvent() {
        given("A track event with default values..") {
            var event: Event = TrackEvent(event: MockProvider.SampleEventName.track)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "track_with_default_arguments")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_trackEvent_properties() {
        given("A track event with properties..") {
            var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "track_with_properties")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_trackEvent_options() {
        given("A track event with options...") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
            
            var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "track_with_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
    
    func test_trackEvent_properties_options() {
        given("A track event with properties & options...") {
            let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
            
            var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties, options: option)
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "track_with_properties_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }
}
