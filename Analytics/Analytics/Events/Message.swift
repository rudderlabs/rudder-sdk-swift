//
//  Message.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - EventType
public enum EventType: String, CaseIterable, Codable {
    case track, screen, alias, identify, group
    
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

// MARK: - TrackEvent
public struct TrackEvent: Message {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    public var event: String
    public var properties: CodableDictionary?
    public var options: CodableDictionary?
    
    public init(event: String, properties: CodableDictionary?, options: CodableDictionary?) {
        self.type = .track
        self.messageId = .randomUUIDString
        self.originalTimeStamp = .currentTimeStamp
        self.event = event
        self.properties = properties
        self.options = options
    }
}
