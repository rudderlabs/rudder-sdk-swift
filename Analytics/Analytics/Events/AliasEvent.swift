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

 - Conforms to: `Message`
 */
struct AliasEvent: Message {

    /// The type of the event, defaulting to `.alias`.
    var type: EventType = .alias

    /// A unique identifier for the message, initialized with a random UUID string.
    var messageId: String = .randomUUIDString

    /// The timestamp of when the event occurred, defaulting to the current time.
    var originalTimeStamp: String = .currentTimeStamp

    /// An optional anonymous identifier for the user associated with the event.
    var anonymousId: String?

    /// The unique identifier for the user.
    var userId: String?

    /// The channel through which the event was sent (e.g., "mobile" or "web").
    var channel: String?

    /// A dictionary specifying integration settings for the event.
    var integrations: [String: Bool]?

    /// The timestamp of when the event was sent.
    var sentAt: String?

    /// Additional context information for the event, provided as a dictionary.
    var context: [String: AnyCodable]?

    /// Custom traits or attributes associated with the event.
    var traits: CodableCollection?

    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The user identity object containing user details, such as identifiers and traits.
    var userIdentity: UserIdentity?

    /// The previous user identifier that the new identifier (`userId`) is linked to.
    var previousId: String

    /**
     Initializes an `AliasEvent` with the specified previous identifier, options, and user identity.

     - Parameters:
        - previousId: The existing identifier for the user that is being linked to a new identifier.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to an empty instance of `UserIdentity`.

     This initializer also applies default values for integrations and context if they are not explicitly provided.
     */
    init(previousId: String, options: RudderOption? = nil, userIdentity: UserIdentity = UserIdentity()) {
        self.previousId = previousId
        self.userIdentity = userIdentity
        self.options = options
        
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
        case originalTimeStamp
        case previousId
        case options
    }
}
