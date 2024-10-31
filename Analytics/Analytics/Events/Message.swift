//
//  Message.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - Message
/**
 This is base class for all events.
 */
protocol Message: Codable {
    var type: EventType { get set }
    var messageId: String { get set }
    var originalTimeStamp: String { get set }
}

// MARK: - TrackEvent
struct TrackEvent: Message {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    public var event: String
    public var properties: CodableCollection?
    public var options: CodableCollection?
    
    public init(event: String, properties: CodableCollection? = nil, options: CodableCollection? = nil) {
        self.type = .track
        self.messageId = .randomUUIDString
        self.originalTimeStamp = .currentTimeStamp
        
        self.event = event
        self.properties = properties
        self.options = options
    }
}

// MARK: - ScreenEvent
struct ScreenEvent: Message {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    public var screenName: String
    public var properties: CodableCollection?
    public var options: CodableCollection?
    
    public init(screenName: String, properties: CodableCollection? = nil, options: CodableCollection? = nil) {
        self.type = .screen
        self.messageId = .randomUUIDString
        self.originalTimeStamp = .currentTimeStamp
        
        self.screenName = screenName
        self.properties = properties
        self.options = options
    }
}

// MARK: - GroupEvent
struct GroupEvent: Message {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    public var groupId: String
    public var traits: CodableCollection?
    public var options: CodableCollection?
    
    init(groupId: String, traits: CodableCollection? = nil, options: CodableCollection? = nil) {
        self.type = .group
        self.messageId = .randomUUIDString
        self.originalTimeStamp = .currentTimeStamp
        
        self.groupId = groupId
        self.traits = traits
        self.options = options
    }
}

// MARK: - FlushEvent
struct FlushEvent: Message {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    public var messageName: String
    
    init(messageName: String) {
        self.type = .flush
        self.messageId = .randomUUIDString
        self.originalTimeStamp = .currentTimeStamp
        
        self.messageName = messageName
    }
}

// MARK: - EventType
enum EventType: String, CaseIterable, Codable {
    case track, screen, group, flush
    
    public var label: String {
        return rawValue.capitalized
    }
}
