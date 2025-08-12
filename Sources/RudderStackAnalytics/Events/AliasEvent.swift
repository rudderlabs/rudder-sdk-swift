//
//  AliasEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 25/01/25.
//

import Foundation

/**
 Represents an alias event in the analytics system.

 The `AliasEvent` struct is used to link a new user identifier (`userId`) to an existing identifier (`previousId`), enabling seamless user tracking across multiple identifiers. This event is particularly useful during user sign-in or account merging scenarios.

 - Conforms to: `Event`
 */
public struct AliasEvent: Event {

    /// The type of the event, defaulting to `.alias`.
    public var type: EventType = .alias

    /// A unique identifier for the event, initialized with a random UUID string.
    public var messageId: String = .randomUUIDString

    /// The timestamp of when the event occurred, defaulting to the current time.
    public var originalTimestamp: String = .currentTimeStamp

    /// An optional anonymous identifier for the user associated with the event.
    public var anonymousId: String?

    /// The unique identifier for the user.
    public var userId: String?

    /// The channel through which the event was sent (e.g., "mobile" or "web").
    public var channel: String?

    /// A dictionary specifying integration settings for the event.
    public var integrations: [String: AnyCodable]?

    /// The timestamp of when the event was sent.
    public var sentAt: String?

    /// Additional context information for the event, provided as a dictionary.
    public var context: [String: AnyCodable]?

    /// Custom traits or attributes associated with the event.
    public var traits: CodableCollection?

    /// Holds the associated values for an event.
    public var options: RudderOption?
    
    /// The user identity object containing user details, such as identifiers and traits.
    public var userIdentity: UserIdentity?

    /// The previous user identifier that the new identifier (`userId`) is linked to.
    public var previousId: String

    /**
     Initializes an `AliasEvent` with the specified previous identifier, options, and user identity.

     - Parameters:
        - previousId: The existing identifier for the user that is being linked to a new identifier.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to `nil`.

     This initializer also applies default values for integrations and context if they are not explicitly provided.
     */
    public init(previousId: String, options: RudderOption? = nil, userIdentity: UserIdentity? = nil) {
        self.previousId = previousId
        self.userIdentity = userIdentity ?? UserIdentity()
        self.options = options ?? RudderOption()
        
        self.addDefaultValues()
    }

    enum CodingKeys: CodingKey {
        case anonymousId
        case userId
        case channel
        case integrations
        case sentAt
        case context
        case traits
        case type
        case messageId
        case originalTimestamp
        case previousId
    }
}
