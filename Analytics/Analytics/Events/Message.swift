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
    public var properties: CodableDictionary?
    public var options: CodableDictionary?
    
    public init(event: String, properties: CodableDictionary? = nil, options: CodableDictionary? = nil) {
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
    public var properties: CodableDictionary?
    public var options: CodableDictionary?
    
    public init(screenName: String, properties: CodableDictionary? = nil, options: CodableDictionary? = nil) {
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
    public var traits: CodableDictionary?
    public var options: CodableDictionary?
    
    init(groupId: String, traits: CodableDictionary? = nil, options: CodableDictionary? = nil) {
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
