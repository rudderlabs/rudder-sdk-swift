//
//  MessageModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("MessageModule Tests")
struct MessageModuleTests {
    
    // MARK: - Track
    @Test("given parameters to create a track event, when created, then verifies event properties")
    func trackEvent() {
        let event = "Sample Event"
        
        var track = TrackEvent(event: event)
        if let updatedTrack = track.updateEventData() as? TrackEvent {
            track = updatedTrack
        }
        
        #expect(track.event == event)
        #expect(track.type == .track)
        #expect(!track.messageId.isEmpty)
        #expect(!track.originalTimestamp.isEmpty)
        #expect(track.channel == Constants.payload.channel)
        #expect(track.integrations != nil)
        #expect(!(track.sentAt?.isEmpty ?? true))
        #expect(track.properties == nil)
    }
    
    @Test("given parameters to create a track event with properties, when created, then verifies event with properties")
    func trackEventProperties() {
        let event = "Sample Event"
        let properties: [String: String] = ["property": "value"]
        
        var track = TrackEvent(event: event, properties: properties)
        if let updatedTrack = track.updateEventData() as? TrackEvent {
            track = updatedTrack
        }
        
        #expect(track.event == event)
        #expect(track.type == .track)
        #expect(!track.messageId.isEmpty)
        #expect(!track.originalTimestamp.isEmpty)
        #expect(track.channel == Constants.payload.channel)
        #expect(!(track.sentAt?.isEmpty ?? true))
        #expect(track.integrations != nil)
        #expect(track.properties != nil)
    }
    
    @Test("given parameters to create a track event with options, when created, then verifies event with options")
    func trackEventOptions() {
        let event = "Sample Event"
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var track = TrackEvent(event: event, options: options)
        if let updatedTrack = track.updateEventData() as? TrackEvent {
            track = updatedTrack
        }
        
        #expect(track.event == event)
        #expect(track.type == .track)
        #expect(!track.messageId.isEmpty)
        #expect(!track.originalTimestamp.isEmpty)
        #expect(track.channel == Constants.payload.channel)
        #expect(track.integrations != nil)
        #expect(!(track.integrations?.isEmpty ?? true))
        #expect(!(track.sentAt?.isEmpty ?? true))
        #expect(!(track.context?.isEmpty ?? true))
        #expect(track.properties == nil)
    }
    
    @Test("given parameters to create a track event with properties and options, when created, then verifies event with all data")
    func trackEventPropertiesOptions() {
        let event = "Sample Event"
        let properties: [String: String] = ["property": "value"]
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var track = TrackEvent(event: event, properties: properties, options: options)
        if let updatedTrack = track.updateEventData() as? TrackEvent {
            track = updatedTrack
        }
        
        #expect(track.event == event)
        #expect(track.type == .track)
        #expect(!track.messageId.isEmpty)
        #expect(!track.originalTimestamp.isEmpty)
        #expect(track.channel == Constants.payload.channel)
        #expect(track.integrations != nil)
        #expect(!(track.integrations?.isEmpty ?? true))
        #expect(!(track.sentAt?.isEmpty ?? true))
        #expect(!(track.context?.isEmpty ?? true))
        #expect(track.properties != nil)
    }
    
    @Test("given fully loaded custom context option for track event, when created, then verifies custom context")
    func trackEventCustomContext() {
        let event = "Sample Event"
        let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["Key_1": ["Key1": "Value1"], "Key_2": ["value1", "value2"], "Key_3": "Value3", "Key_4": 1234, "Key_5": 5678.9, "Key_6": true])
        
        var track = TrackEvent(event: event, options: option)
        if let updatedTrack = track.updateEventData() as? TrackEvent {
            track = updatedTrack
        }
        
        #expect(track.event == event)
        #expect(track.type == .track)
        #expect(!track.messageId.isEmpty)
        #expect(!track.originalTimestamp.isEmpty)
        #expect(track.channel == Constants.payload.channel)
        #expect(track.integrations != nil)
        #expect(!(track.integrations?.isEmpty ?? true))
        #expect(!(track.sentAt?.isEmpty ?? true))
        #expect(!(track.context?.isEmpty ?? true))
    }
    
    // MARK: - Screen
    @Test("given parameters to create a screen event, when created, then verifies screen event properties")
    func screenEvent() {
        let name = "Sample Screen Event"
        
        var screen = ScreenEvent(screenName: name)
        if let updatedScreen = screen.updateEventData() as? ScreenEvent {
            screen = updatedScreen
        }
        
        #expect(screen.event == name)
        #expect(screen.type == .screen)
        #expect(!screen.messageId.isEmpty)
        #expect(!screen.originalTimestamp.isEmpty)
        #expect(screen.channel == Constants.payload.channel)
        #expect(screen.integrations != nil)
        #expect(!(screen.sentAt?.isEmpty ?? true))
        #expect(screen.properties != nil)
    }
    
    @Test("given parameters to create a screen event with properties, when created, then verifies screen event with properties")
    func screenEventProperties() {
        let name = "Sample Screen Event"
        let properties: [String: String] = ["property": "value"]
        
        var screen = ScreenEvent(screenName: name, properties: properties)
        if let updatedScreen = screen.updateEventData() as? ScreenEvent {
            screen = updatedScreen
        }
        
        #expect(screen.event == name)
        #expect(screen.type == .screen)
        #expect(!screen.messageId.isEmpty)
        #expect(!screen.originalTimestamp.isEmpty)
        #expect(screen.channel == Constants.payload.channel)
        #expect(!(screen.sentAt?.isEmpty ?? true))
        #expect(screen.integrations != nil)
        #expect(screen.properties != nil)
    }
    
    @Test("given parameters to create a screen event with options, when created, then verifies screen event with options")
    func screenEventOptions() {
        let name = "Sample Screen Event"
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var screen = ScreenEvent(screenName: name, options: options)
        if let updatedScreen = screen.updateEventData() as? ScreenEvent {
            screen = updatedScreen
        }
        
        #expect(screen.event == name)
        #expect(screen.type == .screen)
        #expect(!screen.messageId.isEmpty)
        #expect(!screen.originalTimestamp.isEmpty)
        #expect(screen.channel == Constants.payload.channel)
        #expect(screen.integrations != nil)
        #expect(!(screen.integrations?.isEmpty ?? true))
        #expect(!(screen.sentAt?.isEmpty ?? true))
        #expect(!(screen.context?.isEmpty ?? true))
        #expect(screen.properties != nil)
    }
    
    @Test("given parameters to create a screen event with properties and options, when created, then verifies screen event with all data")
    func screenEventPropertiesOptions() {
        let name = "Sample Screen Event"
        let properties: [String: String] = ["property": "value"]
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var screen = ScreenEvent(screenName: name, properties: properties, options: options)
        if let updatedScreen = screen.updateEventData() as? ScreenEvent {
            screen = updatedScreen
        }
        
        #expect(screen.event == name)
        #expect(screen.type == .screen)
        #expect(!screen.messageId.isEmpty)
        #expect(!screen.originalTimestamp.isEmpty)
        #expect(screen.channel == Constants.payload.channel)
        #expect(screen.integrations != nil)
        #expect(!(screen.integrations?.isEmpty ?? true))
        #expect(!(screen.sentAt?.isEmpty ?? true))
        #expect(!(screen.context?.isEmpty ?? true))
        #expect(screen.properties != nil)
    }
    
    @Test("given fully loaded custom context option for screen event, when created, then verifies custom context")
    func screenEventCustomContext() {
        let name = "Sample Screen Event"
        let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["Key_1": ["Key1": "Value1"], "Key_2": ["value1", "value2"], "Key_3": "Value3", "Key_4": 1234, "Key_5": 5678.9, "Key_6": true])
        
        var screen = ScreenEvent(screenName: name, options: option)
        if let updatedScreen = screen.updateEventData() as? ScreenEvent {
            screen = updatedScreen
        }
        
        #expect(screen.event == name)
        #expect(screen.type == .screen)
        #expect(!screen.messageId.isEmpty)
        #expect(!screen.originalTimestamp.isEmpty)
        #expect(screen.channel == Constants.payload.channel)
        #expect(screen.integrations != nil)
        #expect(!(screen.integrations?.isEmpty ?? true))
        #expect(!(screen.sentAt?.isEmpty ?? true))
        #expect(!(screen.context?.isEmpty ?? true))
    }
    
    // MARK: - Group
    @Test("given parameters to create a group event, when created, then verifies group event properties")
    func groupEvent() {
        let groupId = "Sample_Group_Id"
        
        var group = GroupEvent(groupId: groupId)
        if let updatedGroup = group.updateEventData() as? GroupEvent {
            group = updatedGroup
        }
        
        #expect(group.groupId == groupId)
        #expect(group.type == .group)
        #expect(!group.messageId.isEmpty)
        #expect(!group.originalTimestamp.isEmpty)
        #expect(group.channel == Constants.payload.channel)
        #expect(group.integrations != nil)
        #expect(!(group.sentAt?.isEmpty ?? true))
        #expect(group.traits == nil)
    }
    
    @Test("given parameters to create a group event with traits, when created, then verifies group event with traits")
    func groupEventTraits() {
        let groupId = "Sample_Group_Id"
        let traits = ["property": "value"]
        
        var group = GroupEvent(groupId: groupId, traits: traits)
        if let updatedGroup = group.updateEventData() as? GroupEvent {
            group = updatedGroup
        }
        
        #expect(group.groupId == groupId)
        #expect(group.type == .group)
        #expect(!group.messageId.isEmpty)
        #expect(!group.originalTimestamp.isEmpty)
        #expect(group.channel == Constants.payload.channel)
        #expect(!(group.sentAt?.isEmpty ?? true))
        #expect(group.integrations != nil)
        #expect(group.traits != nil)
        #expect((group.traits?.dictionary?.count == traits.count))
    }
    
    @Test("given parameters to create a group event with options, when created, then verifies group event with options")
    func groupEventOptions() {
        let groupId = "Sample_Group_Id"
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var group = GroupEvent(groupId: groupId, options: options)
        if let updatedGroup = group.updateEventData() as? GroupEvent {
            group = updatedGroup
        }
        
        #expect(group.groupId == groupId)
        #expect(group.type == .group)
        #expect(!group.messageId.isEmpty)
        #expect(!group.originalTimestamp.isEmpty)
        #expect(group.channel == Constants.payload.channel)
        #expect(group.integrations != nil)
        #expect(!(group.integrations?.isEmpty ?? true))
        #expect(!(group.sentAt?.isEmpty ?? true))
        #expect(!(group.context?.isEmpty ?? true))
        #expect(group.traits == nil)
    }
    
    @Test("given parameters to create a group event with traits and options, when created, then verifies group event with all data")
    func groupEventPropertiesOptions() {
        let groupId = "Sample_Group_Id"
        let traits = ["property": "value"]
        let options = RudderOption(integrations: ["SampleIntegration": false], customContext: ["customContext": ["userContext": "content"]])
        
        var group = GroupEvent(groupId: groupId, traits: traits, options: options)
        if let updatedGroup = group.updateEventData() as? GroupEvent {
            group = updatedGroup
        }
        
        #expect(group.groupId == groupId)
        #expect(group.type == .group)
        #expect(!group.messageId.isEmpty)
        #expect(!group.originalTimestamp.isEmpty)
        #expect(group.channel == Constants.payload.channel)
        #expect(group.integrations != nil)
        #expect(!(group.integrations?.isEmpty ?? true))
        #expect(!(group.sentAt?.isEmpty ?? true))
        #expect(!(group.context?.isEmpty ?? true))
        #expect(group.traits != nil)
        #expect((group.traits?.dictionary?.count == traits.count))
    }
    
    @Test("given fully loaded custom context option for group event, when created, then verifies custom context")
    func groupEventCustomContext() {
        let groupId = "Sample_Group_Id"
        let option = RudderOption(integrations: ["SDK": true, "Facebook" : false], customContext: ["Key_1": ["Key1": "Value1"], "Key_2": ["value1", "value2"], "Key_3": "Value3", "Key_4": 1234, "Key_5": 5678.9, "Key_6": true])
        
        var group = GroupEvent(groupId: groupId, options: option)
        if let updatedGroup = group.updateEventData() as? GroupEvent {
            group = updatedGroup
        }
        
        #expect(group.groupId == groupId)
        #expect(group.type == .group)
        #expect(!group.messageId.isEmpty)
        #expect(!group.originalTimestamp.isEmpty)
        #expect(group.channel == Constants.payload.channel)
        #expect(group.integrations != nil)
        #expect(!(group.integrations?.isEmpty ?? true))
        #expect(!(group.sentAt?.isEmpty ?? true))
        #expect(!(group.context?.isEmpty ?? true))
        #expect(group.traits == nil)
    }
}
