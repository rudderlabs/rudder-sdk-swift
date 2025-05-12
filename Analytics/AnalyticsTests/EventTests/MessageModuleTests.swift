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
                var track = TrackEvent(event: event)
                if let updatedTrack = track.updateEventData() as? TrackEvent {
                    track = updatedTrack
                }
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertEqual(track.channel, Constants.payload.channel)
                    XCTAssertNotNil(track.integrations)
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
                var track = TrackEvent(event: event, properties: properties)
                if let updatedTrack = track.updateEventData() as? TrackEvent {
                    track = updatedTrack
                }
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    
                    XCTAssertEqual(track.channel, Constants.payload.channel)
                    XCTAssertFalse(track.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNotNil(track.integrations)
                    XCTAssertNotNil(track.properties)
                }
                
            }
        }
    }
    
    func test_track_event_options() {
        given("Parameters to create a track event") {
            let event = "Sample Event"
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a track event") {
                var track = TrackEvent(event: event, options: options)
                if let updatedTrack = track.updateEventData() as? TrackEvent {
                    track = updatedTrack
                }
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertEqual(track.channel, Constants.payload.channel)
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
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a track event") {
                var track = TrackEvent(event: event, properties: properties, options: options)
                if let updatedTrack = track.updateEventData() as? TrackEvent {
                    track = updatedTrack
                }
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertEqual(track.channel, Constants.payload.channel)
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
            let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["SK1": ["Key1": "Value1"], "SK2": ["value1", "value2"], "SK3": "Value3", "SK4": 1234, "SK5": 5678.9, "SK6": true])
            
            when("Create a track event") {
                var track = TrackEvent(event: event, options: option)
                if let updatedTrack = track.updateEventData() as? TrackEvent {
                    track = updatedTrack
                }
                
                then("Verify the track event") {
                    XCTAssertEqual(track.event, event)
                    XCTAssertEqual(track.type, .track)
                    XCTAssertFalse(track.messageId.isEmpty)
                    XCTAssertFalse(track.originalTimeStamp.isEmpty)
                    XCTAssertEqual(track.channel, Constants.payload.channel)
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
                var screen = ScreenEvent(screenName: name)
                if let updatedScreen = screen.updateEventData() as? ScreenEvent {
                    screen = updatedScreen
                }
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertEqual(screen.channel, Constants.payload.channel)
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertNotNil(screen.properties)
                }
            }
        }
    }
    
    func test_screen_event_properties() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let properties: [String: String] = ["property": "value"]
            
            when("Create a screen event") {
                var screen = ScreenEvent(screenName: name, properties: properties)
                if let updatedScreen = screen.updateEventData() as? ScreenEvent {
                    screen = updatedScreen
                }
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    
                    XCTAssertEqual(screen.channel, Constants.payload.channel)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertNotNil(screen.properties)
                }
                
            }
        }
    }
    
    func test_screen_event_options() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a screen event") {
                var screen = ScreenEvent(screenName: name, options: options)
                if let updatedScreen = screen.updateEventData() as? ScreenEvent {
                    screen = updatedScreen
                }
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertEqual(screen.channel, Constants.payload.channel)
                    XCTAssertNotNil(screen.integrations)
                    XCTAssertFalse(screen.integrations?.isEmpty ?? true)
                    XCTAssertFalse(screen.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(screen.context?.isEmpty ?? true)
                    XCTAssertNotNil(screen.properties)
                }
                
            }
        }
    }
    
    func test_screen_event_properties_options() {
        given("Parameters to create a screen event") {
            let name = "Sample Screen Event"
            let properties: [String: String] = ["property": "value"]
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a screen event") {
                var screen = ScreenEvent(screenName: name, properties: properties, options: options)
                if let updatedScreen = screen.updateEventData() as? ScreenEvent {
                    screen = updatedScreen
                }
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertEqual(screen.channel, Constants.payload.channel)
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
            let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["SK1": ["Key1": "Value1"], "SK2": ["value1", "value2"], "SK3": "Value3", "SK4": 1234, "SK5": 5678.9, "SK6": true])
            
            when("Create a screen event") {
                var screen = ScreenEvent(screenName: name, options: option)
                if let updatedScreen = screen.updateEventData() as? ScreenEvent {
                    screen = updatedScreen
                }
                
                then("Verify the screen event") {
                    XCTAssertEqual(screen.event, name)
                    XCTAssertEqual(screen.type, .screen)
                    XCTAssertFalse(screen.messageId.isEmpty)
                    XCTAssertFalse(screen.originalTimeStamp.isEmpty)
                    XCTAssertEqual(screen.channel, Constants.payload.channel)
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
                var group = GroupEvent(groupId: groupId)
                if let updatedGroup = group.updateEventData() as? GroupEvent {
                    group = updatedGroup
                }
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertEqual(group.channel, Constants.payload.channel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertNil(group.traits)
                }
            }
        }
    }
    
    func test_group_event_traits() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let traits = ["property": "value"]
            
            when("Create a group event") {
                var group = GroupEvent(groupId: groupId, traits: traits)
                if let updatedGroup = group.updateEventData() as? GroupEvent {
                    group = updatedGroup
                }
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    
                    XCTAssertEqual(group.channel, Constants.payload.channel)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    
                    XCTAssertNotNil(group.integrations)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == traits.count))
                }
                
            }
        }
    }
    
    func test_group_event_options() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a group event") {
                var group = GroupEvent(groupId: groupId, options: options)
                if let updatedGroup = group.updateEventData() as? GroupEvent {
                    group = updatedGroup
                }
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertEqual(group.channel, Constants.payload.channel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNil(group.traits)
                }
                
            }
        }
    }
    
    func test_group_event_properties_options() {
        given("Parameters to create a group event") {
            let groupId = "Sample_Group_Id"
            let traits = ["property": "value"]
            let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
            
            when("Create a group event") {
                var group = GroupEvent(groupId: groupId, traits: traits, options: options)
                if let updatedGroup = group.updateEventData() as? GroupEvent {
                    group = updatedGroup
                }
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertEqual(group.channel, Constants.payload.channel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNotNil(group.traits)
                    XCTAssertTrue((group.traits?.dictionary?.count == traits.count))
                }
                
            }
        }
    }
    
    func test_group_event_custom_context() {
        given("Fully loaded custom context option") {
            let groupId = "Sample_Group_Id"
            let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["SK1": ["Key1": "Value1"], "SK2": ["value1", "value2"], "SK3": "Value3", "SK4": 1234, "SK5": 5678.9, "SK6": true])
            
            when("Create a group event") {
                var group = GroupEvent(groupId: groupId, options: option)
                if let updatedGroup = group.updateEventData() as? GroupEvent {
                    group = updatedGroup
                }
                
                then("Verify the group event") {
                    XCTAssertEqual(group.groupId, groupId)
                    XCTAssertEqual(group.type, .group)
                    XCTAssertFalse(group.messageId.isEmpty)
                    XCTAssertFalse(group.originalTimeStamp.isEmpty)
                    XCTAssertEqual(group.channel, Constants.payload.channel)
                    XCTAssertNotNil(group.integrations)
                    XCTAssertFalse(group.integrations?.isEmpty ?? true)
                    XCTAssertFalse(group.sentAt?.isEmpty ?? true)
                    XCTAssertFalse(group.context?.isEmpty ?? true)
                    XCTAssertNil(group.traits)
                }
            }
        }
    }
}
