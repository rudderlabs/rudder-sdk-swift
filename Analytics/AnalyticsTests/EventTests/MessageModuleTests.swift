//
//  MessageModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 13/11/24.
//

import XCTest
@testable import Analytics

final class MessageModuleTests: XCTestCase {
    
    // MARK: - Track
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
    
    func test_track_event_custom_context() {
        given("Fully loaded custom context option") {
            let event = "Sample Event"
            let option = RudderOptions()
            .addIntegration("SDK", isEnabled: true)
            .addIntegration("Facebook", isEnabled: false)
            .addCustomContext(["Key1": "Value1"], key: "SK1")
            .addCustomContext(["value1", "value2"], key: "SK2")
            .addCustomContext("Value3", key: "SK3")
            .addCustomContext(1234, key: "SK4")
            .addCustomContext(5678.9, key: "SK5")
            .addCustomContext(true, key: "SK6")
            
            when("Create a track event") {
                let track = TrackEvent(event: event, options: option)
                
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
                }
            }
        }
    }
    
    // MARK: - Screen
    func test_screen_event() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            
            when("Create a screen event") {
                let screen = ScreenEvent(screenName: name)
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(screen.anonymousId)
                    XCTAssertEqual(screen.channel, Constants.defaultChannel)
                    XCTAssertNil(screen.integrations)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertNil(screen.properties)
                }
            }
        }
    }
    
    func test_screen_event_properties() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let properties: [String: String] = ["property": "value"]
            
            when("Create a screen event") {
                let screen = ScreenEvent(screenName: name, properties: properties)
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    
                    XCTAssertNotNil(screen.anonymousId)
                    XCTAssertEqual(screen.channel, Constants.defaultChannel)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNil(screen.integrations)
                    XCTAssertNotNil(screen.properties)
                }
                
            }
        }
    }
    
    func test_screen_event_options() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a screen event") {
                let screen = ScreenEvent(screenName: name, options: options)
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(screen.anonymousId)
                    XCTAssertEqual(screen.channel, Constants.defaultChannel)
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertFalse(screen.integrations?.isEmpty ?? true)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(screen.context?.isEmpty ?? true)
                    XCTAssertNil(screen.properties)
                }
                
            }
        }
    }
    
    func test_screen_event_properties_options() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let properties: [String: String] = ["property": "value"]
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a screen event") {
                let screen = ScreenEvent(screenName: name, properties: properties, options: options)
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(screen.anonymousId)
                    XCTAssertEqual(screen.channel, Constants.defaultChannel)
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertFalse(screen.integrations?.isEmpty ?? true)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(screen.context?.isEmpty ?? true)
                    XCTAssertNotNil(screen.properties)
                }
                
            }
        }
    }
    
    func test_screen_event_custom_context() {
        given("Fully loaded custom context option") {
            let name = "Sample Screen Event"
            let option = RudderOptions()
            .addIntegration("SDK", isEnabled: true)
            .addIntegration("Facebook", isEnabled: false)
            .addCustomContext(["Key1": "Value1"], key: "SK1")
            .addCustomContext(["value1", "value2"], key: "SK2")
            .addCustomContext("Value3", key: "SK3")
            .addCustomContext(1234, key: "SK4")
            .addCustomContext(5678.9, key: "SK5")
            .addCustomContext(true, key: "SK6")
            
            when("Create a screen event") {
                let screen = ScreenEvent(screenName: name, options: option)
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(screen.anonymousId)
                    XCTAssertEqual(screen.channel, Constants.defaultChannel)
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertFalse(screen.integrations?.isEmpty ?? true)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(screen.context?.isEmpty ?? true)
                }
            }
        }
    }
    
    // MARK: - Group
    func test_group_event() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            
            when("Create a group event") {
                let group = GroupEvent(groupId: groupId)
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(group.anonymousId)
                    XCTAssertEqual(group.channel, Constants.defaultChannel)
                    XCTAssertNil(group.integrations)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == 1))
                }
            }
        }
    }
    
    func test_group_event_traits() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let traits = ["property": "value"]
            
            when("Create a group event") {
                let group = GroupEvent(groupId: groupId, traits: traits)
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    
                    XCTAssertNotNil(group.anonymousId)
                    XCTAssertEqual(group.channel, Constants.defaultChannel)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNil(group.integrations)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == 2))
                }
                
            }
        }
    }
    
    func test_group_event_options() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a group event") {
                let group = GroupEvent(groupId: groupId, options: options)
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(group.anonymousId)
                    XCTAssertEqual(group.channel, Constants.defaultChannel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNotNil(group.traits)
                }
                
            }
        }
    }
    
    func test_group_event_properties_options() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let traits = ["property": "value"]
            let options = RudderOptions()
                .addIntegration("SampleIntegration", isEnabled: false)
                .addCustomContext(["userContext": "content"], key: "customContext")
            
            when("Create a group event") {
                let group = GroupEvent(groupId: groupId, traits: traits, options: options)
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(group.anonymousId)
                    XCTAssertEqual(group.channel, Constants.defaultChannel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == 2))
                }
                
            }
        }
    }
    
    func test_group_event_custom_context() {
        given("Fully loaded custom context option") {
            let groupId = "Sample_Group_Id"
            let option = RudderOptions()
            .addIntegration("SDK", isEnabled: true)
            .addIntegration("Facebook", isEnabled: false)
            .addCustomContext(["Key1": "Value1"], key: "SK1")
            .addCustomContext(["value1", "value2"], key: "SK2")
            .addCustomContext("Value3", key: "SK3")
            .addCustomContext(1234, key: "SK4")
            .addCustomContext(5678.9, key: "SK5")
            .addCustomContext(true, key: "SK6")
            
            when("Create a group event") {
                let group = GroupEvent(groupId: groupId, options: option)
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertNotNil(group.anonymousId)
                    XCTAssertEqual(group.channel, Constants.defaultChannel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == 1))
                }
            }
        }
    }
}
