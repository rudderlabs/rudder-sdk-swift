//
//  TrackEventTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/11/24.
//

import XCTest
@testable import Analytics

final class TrackEventTests: XCTestCase {
    
    func test_defaultTrackEvent() {
        given("A track event with default values..") {
            var event: Message = TrackEvent(event: MockProvider.SampleEventName.track)
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
            var event: Message = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties)
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
            let option = RudderOption().addCustomContext(MockProvider.sampleEventproperties, key: "customContext")
            
            MockProvider.sampleEventIntegrations.forEach { integration in
                option.addIntegration(integration.key, isEnabled: integration.value)
            }
            
            var event: Message = TrackEvent(event: MockProvider.SampleEventName.track, options: option)
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
            let option = RudderOption().addCustomContext(MockProvider.sampleEventproperties, key: "customContext")
            
            MockProvider.sampleEventIntegrations.forEach { integration in
                option.addIntegration(integration.key, isEnabled: integration.value)
            }
            
            var event: Message = TrackEvent(event: MockProvider.SampleEventName.track, properties: MockProvider.sampleEventproperties, options: option)
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
