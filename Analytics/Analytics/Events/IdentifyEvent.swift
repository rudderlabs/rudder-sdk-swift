//
//  IdentifyEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 21/01/25.
//

import Foundation

/**
 Represents an identify event in the analytics system.

 This struct conforms to the `Event` protocol and is used to associate user data, such as traits and identifiers.

 - Conforms to: `Event`
 */
struct IdentifyEvent: Event {
    
    /// The type of the event, defaulting to `.identify`.
    var type: EventType = .identify

    /// A unique identifier for the event, initialized with a random UUID string.
    var messageId: String = .randomUUIDString

    /// The timestamp of when the event occurred, defaulting to the current time.
    var originalTimestamp: String = .currentTimeStamp

    /// The anonymous identifier for the user associated with the event.
    var anonymousId: String?

    /// The channel through which the event was sent (e.g., "mobile" or "web").
    var channel: String?

    /// A dictionary of integration settings for the event.
    var integrations: [String: AnyCodable]?

    /// The timestamp of when the event was sent.
    var sentAt: String?

    /// Additional context information for the event, provided as a dictionary.
    var context: [String: AnyCodable]?

    /// Custom traits or attributes associated with the user profile.
    var traits: CodableCollection?

    /// The name of the event being tracked.
    var event: String
    
    /// The unique identifier for the user.
    var userId: String?

    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    var userIdentity: UserIdentity?

    /**
     Initializes an `IdentifyEvent` with the specified traits, options, and user identity values.

     - Parameters:
        - traits: Custom traits or attributes for the user. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to an empty instance of `RudderOption`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to an empty instance of `UserIdentity`.

     This initializer also populates default values such as the anonymous ID and integrations if they are not provided.
     */
    init(options: RudderOption? = RudderOption(), userIdentity: UserIdentity = UserIdentity()) {
        self.userIdentity = userIdentity
        self.event = self.type.rawValue
        self.options = options
        
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
        case userId
        case event
    }
}
