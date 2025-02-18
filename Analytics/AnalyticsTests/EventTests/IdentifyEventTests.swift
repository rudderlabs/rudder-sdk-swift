//
//  IdentifyEventTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 25/01/25.
//

import XCTest
@testable import Analytics

final class IdentifyEventTests: XCTestCase {
    
    func test_defaultIdentifyEvent() {
        given("A identify event with userId provided without any options..") {
            var event: Message = IdentifyEvent(userIdentity: UserIdentity(userId: "Test_User_Id"))
            event = event.updateEventData()
            MockHelper.resetDynamicValues(&event)
            
            when("Serialize the event..") {
                guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                
                then("matches the expected JSON") {
                    guard let expected = MockHelper.readJson(from: "identify_with_default_arguments")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                    XCTAssertEqual(json, expected)
                }
            }
        }
    }

     func test_identifyEvent_traits() {
         given("A identify event with userId and traits without any options..") {
             var event: Message = IdentifyEvent(userIdentity: UserIdentity(userId: "Test_User_Id", traits: MockProvider.sampleEventproperties))
             event = event.updateEventData()
             MockHelper.resetDynamicValues(&event)
             
             when("Serialize the event..") {
                 guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                 
                 then("matches the expected JSON") {
                     guard let expected = MockHelper.readJson(from: "identify_with_traits")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                     XCTAssertEqual(json, expected)
                 }
             }
         }
     }
     
     func test_identifyEvent_options() {
         given("A identify event with userId and options..") {
             let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
             
             var event: Message = IdentifyEvent(options: option, userIdentity: UserIdentity(userId: "Test_User_Id"))
             event = event.updateEventData()
             MockHelper.resetDynamicValues(&event)
             
             when("Serialize the event..") {
                 guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                 
                 then("matches the expected JSON") {
                     guard let expected = MockHelper.readJson(from: "identify_with_options")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                     XCTAssertEqual(json, expected)
                 }
             }
         }
     }
     
     func test_identifyEvent_traits_options() {
         given("A identify event with userId, traits, externalIds and options..") {
             let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
             
             var event: Message = IdentifyEvent(options: option, userIdentity: UserIdentity(userId: "Test_User_Id", traits: MockProvider.sampleEventproperties, externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")]))
             event = event.updateEventData()
             MockHelper.resetDynamicValues(&event)
             
             when("Serialize the event..") {
                 guard let json = event.jsonString?.trimmed else { XCTFail("Failed to serialize the event."); return }
                 
                 then("matches the expected JSON") {
                     guard let expected = MockHelper.readJson(from: "identify_with_all_values")?.trimmed else { XCTFail("Failed to read the expected JSON."); return }
                     XCTAssertEqual(json, expected)
                 }
             }
         }
     }
}

