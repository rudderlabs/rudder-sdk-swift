//
//  MessageEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - EventType
@objc
public enum EventType: Int, Codable, CaseIterable {
    case track, screen, alias, identify, group
    
    public var title: String {
        return switch(self) {
        case .track:
            "Track"
        case .screen:
            "Screen"
        case .alias:
            "Alias"
        case .identify:
            "Identify"
        case .group:
            "Group"
        }
    }
    
    public static func from(title: String) -> EventType? {
        return EventType.allCases.first { $0.title == title }
    }
}

// MARK: - MessageEvent
/**
 This is base class for all events.
 */
@objcMembers
public class MessageEvent: NSObject, Codable {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    init(type: EventType, messageId: String, originalTimeStamp: String) {
        self.type = type
        self.messageId = messageId
        self.originalTimeStamp = originalTimeStamp
    }
    
    // Required init for decoding
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let typeTitle = try container.decode(String.self, forKey: .type)
        guard let type = EventType.from(title: typeTitle) else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
        }
        self.type = type
        self.messageId = try container.decode(String.self, forKey: .messageId)
        self.originalTimeStamp = try container.decode(String.self, forKey: .originalTimeStamp)
    }
    
    // Encoding method
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.title, forKey: .type)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(originalTimeStamp, forKey: .originalTimeStamp)
    }
    
    // Define coding keys for encoding and decoding
    private enum CodingKeys: String, CodingKey {
        case type
        case messageId
        case originalTimeStamp
    }
}

// MARK: - TrackEvent
@objcMembers
public class TrackEvent: MessageEvent {
    
    var event: String
    var properties: RudderProperties
    var options: RudderOptions
    
    init(event: String, properties: RudderProperties, options: RudderOptions,
         type: EventType = .track, messageId: String = .randomUUIDString, originalTimeStamp: String = .currentTimeStamp) {
        self.event = event
        self.properties = properties
        self.options = options
        
        super.init(type: type, messageId: messageId, originalTimeStamp: originalTimeStamp)
    }
    
    // Required init for decoding
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.event = try container.decode(String.self, forKey: .event)
        self.properties = try container.decodeDictionary(forKey: .properties)
        self.options = try container.decodeDictionary(forKey: .options)
        
        // Decode the superclass properties
        try super.init(from: decoder)
    }
    
    // Encoding method
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(properties, forKey: .properties)
        try container.encode(options, forKey: .options)
        
        // Encode the superclass properties
        try super.encode(to: encoder)
    }
    
    // Define coding keys for encoding and decoding
    private enum CodingKeys: String, CodingKey {
        case event
        case properties
        case options
    }
}
