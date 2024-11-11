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
    var sentAt: String? { get set }
    
//    var context: AnalyticsContext { get set }
//    var userId: String? { get set }
//    var integrations: [String: Bool]? { get set }
    
    var type: EventType { get set }
    var messageId: String { get set }
    var originalTimeStamp: String { get set }
}

// MARK: - TrackEvent
struct TrackEvent: Message {
    var type: EventType = .track
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var sentAt: String?
    
    var event: String
    var properties: CodableCollection?
    var options: RudderOptions?
    
    init(event: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.event = event
        self.properties = CodableCollection(dictionary: properties)
        self.options = options
    }
}

// MARK: - ScreenEvent
struct ScreenEvent: Message {
    var type: EventType = .screen
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var sentAt: String?
    
    var screenName: String
    var properties: CodableCollection?
    var options: RudderOptions?
    
    init(screenName: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.screenName = screenName
        self.properties = CodableCollection(dictionary: properties)
        self.options = options
    }
}

// MARK: - GroupEvent
struct GroupEvent: Message {
    var type: EventType = .group
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var sentAt: String?
    
    var groupId: String
    var traits: CodableCollection?
    var options: RudderOptions?
    
    init(groupId: String, traits: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.groupId = groupId
        self.traits = CodableCollection(dictionary: traits)
        self.options = options
    }
}

// MARK: - FlushEvent
struct FlushEvent: Message {
    var type: EventType = .flush
    var messageId: String = .randomUUIDString
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    var channel: String?
    var sentAt: String?
    
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

// MARK: - RudderOptionType
protocol RudderOptionType: Codable {
    var integrations: [String: Bool]? { get set }
    var customContext: CodableCollection? { get set }
}

// MARK: - RudderOptions
public struct RudderOptions: RudderOptionType {
    var integrations: [String: Bool]?
    var customContext: CodableCollection?
    
    public init?(integrations: [String : Bool]? = nil, customContext: CodableCollection? = nil) {
        guard integrations != nil || customContext != nil else { return nil }
        self.integrations = integrations
        self.customContext = customContext
    }
}

// MARK: - RudderIdentifyOptionType
protocol RudderIdentifyOptionType: RudderOptionType {
    var externalIds: [ExternalId]? { get set }
}

// MARK: - RudderIdentifyOptions
public struct RudderIdentifyOptions: RudderIdentifyOptionType {
    var integrations: [String: Bool]?
    var customContext: CodableCollection?
    var externalIds: [ExternalId]?
    
    public init?(integrations: [String : Bool]? = nil, customContext: [String : Any]? = nil, externalIds: [ExternalId]? = nil) {
        guard integrations != nil || externalIds != nil || customContext != nil else { return nil }
        self.integrations = integrations
        self.externalIds = externalIds
        self.customContext = CodableCollection(dictionary: customContext)
    }
}

// MARK: - ExternalId
public struct ExternalId: Codable {
    var type: String
    var id: String
    
    public init(type: String, id: String) {
        self.type = type
        self.id = id
    }
}
