//
//  FlushEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 31/12/24.
//

import Foundation

// MARK: - FlushEvent

/**
 Represents a flush event in the analytics system.

 The `FlushEvent` is a specialized event type used to signal the system to flush stored events for processing and upload.
 It conforms to the `Event` protocol and contains necessary metadata for event management.

 - Conforms to: `Event`
 */
struct FlushEvent: Event {
    
    /// The type of the event, defaulting to `.flush`.
    var type: EventType = .flush
    
    /// A unique identifier for the message.
    var messageId: String = .randomUUIDString
    
    /// The timestamp of when the event occurred, defaulting to the current time.
    var originalTimeStamp: String = .currentTimeStamp
    
    /// The anonymous identifier for the user associated with the event.
    var anonymousId: String?
    
    /// The channel through which the event was sent.
    var channel: String?
    
    /// A dictionary of integration settings for the event.
    var integrations: [String: AnyCodable]?
    
    /// The timestamp of when the event was sent.
    var sentAt: String?
    
    /// Additional context information for the event, provided as a dictionary.
    var context: [String: AnyCodable]?
    
    /// Custom traits or attributes, not applicable for a flush event.
    var traits: CodableCollection?
    
    /// The name of the message, indicating its specific purpose within the system.
    var messageName: String

    /// The unique identifier for the user.
    var userId: String?
    
    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    var userIdentity: UserIdentity?
    
    /**
     Initializes a `FlushEvent` with a specified message name.

     - Parameter messageName: The name of the flush message, typically used to describe its purpose or trigger source.
     */
    init(messageName: String) {
        self.messageName = messageName
    }
    
    enum CodingKeys: CodingKey {
        case type
        case messageId
        case originalTimeStamp
        case anonymousId
        case channel
        case integrations
        case sentAt
        case context
        case traits
        case messageName
        case userId
    }
}
