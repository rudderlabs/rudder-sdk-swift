//
//  MessageModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 13/11/24.
//

import XCTest
@testable import Analytics

final class MessageModuleTests: XCTestCase {
    
    func test_track_event() {
        given("Parameters to create a track event") {
            let event = "Sample Event"
            
            when("Create a track event") {
                let track = TrackEvent(event: event)
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(track.anonymousId)
                    XCTAssertEqual(track.channel, Constants.defaultChannel)
                    XCTAssertNil(track.integrations)
                    XCTAssertFalse(track.sentAt?.isEmpty ?? true)
                    XCTAssertNil(track.properties)
                }
            }
        }
    }
    
    func test_track_event_properties() {
        given("Parameters to create a track event") {
            let event = "Sample Event"
            let properties: [String: String] = ["property": "value"]
            
            when("Create a track event") {
                let track = TrackEvent(event: event, properties: properties)
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    
                    XCTAssertNotNil(track.anonymousId)
                    XCTAssertEqual(track.channel, Constants.defaultChannel)
                    XCTAssertFalse(track.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNil(track.integrations)
                    XCTAssertNotNil(track.properties)
                }
                
            }
        }
    }
    
    func test_track_event_options() {
        given("Parameters to create a track event") {
            let event = "Sample Event"
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a track event") {
                let track = TrackEvent(event: event, options: options)
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(track.anonymousId)
                    XCTAssertEqual(track.channel, Constants.defaultChannel)
                    XCTAssertNotNil(track.integrations)
                    XCTAssertFalse(track.integrations?.isEmpty ?? true)
                    XCTAssertFalse(track.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(track.context?.isEmpty ?? true)
                    XCTAssertNil(track.properties)
                }
                
            }
        }
    }
    
    func test_track_event_properties_options() {
        given("Parameters to create a track event") {
            let event = "Sample Event"
            let properties: [String: String] = ["property": "value"]
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a track event") {
                let track = TrackEvent(event: event, properties: properties, options: options)
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(track.anonymousId)
                    XCTAssertEqual(track.channel, Constants.defaultChannel)
                    XCTAssertNotNil(track.integrations)
                    XCTAssertFalse(track.integrations?.isEmpty ?? true)
                    XCTAssertFalse(track.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(track.context?.isEmpty ?? true)
                    XCTAssertNotNil(track.properties)
                }
                
            }
        }
    }
}
