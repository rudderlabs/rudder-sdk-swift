//
//  Message.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - Message
/**
 This is base protocol for all events.
 */
protocol Message: Codable {
    var anonymousId: String? { get set }
    var channel: String? { get set }
    var integrations: [String: Bool]? { get set }
    var sentAt: String? { get set }
    var context: [String: AnyCodable]? { get set }
    
    var type: EventType { get set }
    var messageId: String { get set }
    var originalTimeStamp: String { get set }
}

extension Message {
    /**
     This function will serve as a shared utility for adding default or standard values.
     */
    mutating func addDefaultValues() {
        self.channel = Constants.defaultChannel
        self.sentAt = Constants.defaultSentAtPlaceholder
        
        // TODO: Needs to be modified in future..
        self.anonymousId = .randomUUIDString
        //context
    }
}

// MARK: - TrackEvent
/**
 This model is based on the `Message` protocol and is designed for creating `Track` events.
 */
struct TrackEvent: Message {
    var type: EventType = .track
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: AnyCodable]?
    
    var event: String
    var properties: CodableCollection?
    
    init(event: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.event = event
        self.properties = CodableCollection(dictionary: properties)
        self.integrations = options == nil ? Constants.defaultIntegration : options?.integrations
        
        self.context = options?.customContext?.isEmpty == false ?
        options?.customContext?.compactMapValues { AnyCodable($0) } : nil
        
        self.addDefaultValues()
    }
}

// MARK: - ScreenEvent
/**
 This model is based on the `Message` protocol and is designed for creating `Screen` events.
 */
struct ScreenEvent: Message {
    var type: EventType = .screen
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: AnyCodable]?
    
    var event: String
    var properties: CodableCollection?
    
    init(screenName: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.event = screenName
        self.properties = CodableCollection(dictionary: properties)
        self.integrations = options == nil ? Constants.defaultIntegration : options?.integrations
        
        self.context = options?.customContext?.isEmpty == false ?
            options?.customContext?.compactMapValues { AnyCodable($0) } : nil
        
        self.addDefaultValues()
    }
}

// MARK: - GroupEvent
/**
 This model is based on the `Message` protocol and is designed for creating `Group` events.
 */
struct GroupEvent: Message {
    var type: EventType = .group
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: AnyCodable]?
    
    var groupId: String
    var traits: CodableCollection?
    
    init(groupId: String, traits: RudderTraits? = nil, options: RudderOptions? = nil) {
        self.groupId = groupId
        self.addDefaultValues()
        
        var updatedTraits = traits ?? RudderTraits()
        updatedTraits["anonymousId"] = self.anonymousId
        
        self.traits = CodableCollection(dictionary: updatedTraits)
        self.integrations = options == nil ? Constants.defaultIntegration : options?.integrations
        
        self.context = options?.customContext?.isEmpty == false ?
        options?.customContext?.compactMapValues { AnyCodable($0) } : nil
    }
}

// MARK: - FlushEvent
/**
 This model is based on the `Message` protocol and is designed for creating `Flush` events.
 */
struct FlushEvent: Message {
    var type: EventType = .flush
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: AnyCodable]?
    
    var messageName: String
    
    init(messageName: String) {
        self.messageName = messageName
    }
}

// MARK: - EventType
/**
 Enum values used to specify the type of message event.
 */
enum EventType: String, CaseIterable, Codable {
    case track, screen, group, flush
    
    public var label: String {
        return rawValue.capitalized
    }
}
