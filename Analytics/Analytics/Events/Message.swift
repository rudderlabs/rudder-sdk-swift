//
//  Message.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - EventType
public enum EventType: String, CaseIterable, Codable {
    case track, screen, group, flush
    
    public var label: String {
        return rawValue.capitalized
    }
}

// MARK: - Message
/**
 This is base class for all events.
 */
public protocol Message: Codable {
    var type: EventType { get set }
    var messageId: String { get set }
    var originalTimeStamp: String { get set }
}

extension Message {
    public var messageId: String {
        get {
            return .randomUUIDString
        }
        set{}
    }
    
    public var originalTimeStamp: String {
        get {
            return .currentTimeStamp
        }
        set{}
    }
}

// MARK: - TrackEvent
public struct TrackEvent: Message {
    public var type: EventType
    
    public var event: String
    public var properties: CodableDictionary?
    public var options: CodableDictionary?
    
    public init(event: String, properties: CodableDictionary?, options: CodableDictionary?) {
        self.type = .track
        self.event = event
        self.properties = properties
        self.options = options
    }
}

public struct ScreenEvent: Message {
    public var type: EventType
    
    public var screenName: String
    public var properties: CodableDictionary?
    public var options: CodableDictionary?
    
    public init(screenName: String, properties: CodableDictionary?, options: CodableDictionary?) {
        self.type = .screen
        self.screenName = screenName
        self.properties = properties
        self.options = options
    }
}

public struct GroupEvent: Message {
    public var type: EventType
    
    public var groupId: String
    public var traits: CodableDictionary?
    public var options: CodableDictionary?
    
    init(groupId: String, traits: CodableDictionary? = nil, options: CodableDictionary? = nil) {
        self.type = .group
        self.groupId = groupId
        self.traits = traits
        self.options = options
    }
}

public struct FlushEvent: Message {
    public var type: EventType
    
    public var messageName: String
    
    init(messageName: String) {
        self.type = .flush
        self.messageName = messageName
    }
}
