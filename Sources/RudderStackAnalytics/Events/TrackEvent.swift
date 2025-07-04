//
//  TrackEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 31/12/24.
//

import Foundation

// MARK: - TrackEvent

/**
 Represents a tracking event in the analytics system.

 This struct conforms to the `Event` protocol and is used to capture information about a specific event that occurred in the application, such as user interactions or custom events.

 - Conforms to: `Event`
 */
struct TrackEvent: Event {
    
    /// The type of the event, defaulting to `.track`.
    var type: EventType = .track
    
    /// A unique identifier for the event.
    var messageId: String = .randomUUIDString
    
    /// The timestamp of when the event occurred, defaulting to the current time.
    var originalTimestamp: String = .currentTimeStamp
    
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
    
    /// Custom traits or attributes associated with the event.
    var traits: CodableCollection?
    
    /// The name of the event being tracked.
    var event: String
    
    /// The unique identifier for the user.
    var userId: String?
    
    /// Additional properties or metadata for the event.
    var properties: CodableCollection?

    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    var userIdentity: UserIdentity?
    
    /**
     Initializes a `TrackEvent` with the specified event name, properties, options and user identity values.

     - Parameters:
        - event: The name of the event being tracked.
        - properties: Additional properties or metadata associated with the event. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to `nil`.

     This initializer also populates default values such as the anonymous ID and integrations if they are not provided.
     */
    init(event: String, properties: Properties? = nil, options: RudderOption? = nil, userIdentity: UserIdentity? = nil) {
        self.event = event
        self.properties = CodableCollection(dictionary: properties)
        self.userIdentity = userIdentity ?? UserIdentity()
        self.options = options ?? RudderOption()
        
        self.addDefaultValues()
    }
    
    enum CodingKeys: CodingKey {
        case type
        case messageId
        case originalTimestamp
        case anonymousId
        case channel
        case integrations
        case sentAt
        case context
        case traits
        case event
        case properties
        case userId
    }
}
