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
    var anonymousId: String? { get set }
    var channel: String? { get set }
    var integrations: [String: Bool]? { get set }
    var sentAt: String? { get set }
    var context: [String: CodableCollection]? { get set }
    
    var type: EventType { get set }
    var messageId: String { get set }
    var originalTimeStamp: String { get set }
}

extension Message {
    mutating func addDefaultValues() {
        self.channel = Constants.defaultChannel
        self.sentAt = Constants.defaultSentAtPlaceholder
        
        // TODO: Needs to be modified in future..
        self.anonymousId = .randomUUIDString
        //context
    }
}

// MARK: - TrackEvent
struct TrackEvent: Message {
    var type: EventType = .track
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: CodableCollection]?
    
    var event: String
    var properties: CodableCollection?
    
    init(event: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.event = event
        self.properties = CodableCollection(dictionary: properties)
        self.integrations = options?.integrations
        
        self.context = options?.customContext?.isEmpty == false ?
            options?.customContext?.compactMapValues { CodableCollection(dictionary: $0) } : nil
        
        self.addDefaultValues()
    }
}

// MARK: - ScreenEvent
struct ScreenEvent: Message {
    var type: EventType = .screen
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: CodableCollection]?
    
    var screenName: String
    var properties: CodableCollection?
    
    init(screenName: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.screenName = screenName
        self.properties = CodableCollection(dictionary: properties)
        self.integrations = options?.integrations
        
        self.addDefaultValues()
    }
}

// MARK: - GroupEvent
struct GroupEvent: Message {
    var type: EventType = .group
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: CodableCollection]?
    
    var groupId: String
    var traits: CodableCollection?
    
    init(groupId: String, traits: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.groupId = groupId
        self.traits = CodableCollection(dictionary: traits)
        self.integrations = options?.integrations
        
        self.addDefaultValues()
    }
}

// MARK: - FlushEvent
struct FlushEvent: Message {
    var type: EventType = .flush
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var integrations: [String: Bool]?
    var sentAt: String?
    var context: [String: CodableCollection]?
    
    var messageName: String
    
    init(messageName: String) {
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
