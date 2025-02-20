//
//  GroupEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 31/12/24.
//

import Foundation

// MARK: - GroupEvent

/**
 Represents a group event in the analytics system.

 This struct conforms to the `Event` protocol and is used to associate a user with a specific group, such as a team, organization, or other collection.

 - Conforms to: `Event`
 */
struct GroupEvent: Event {
    
    /// The type of the event, defaulting to `.group`.
    var type: EventType = .group
    
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
    
    /// The unique identifier for the user.
    var userId: String?
    
    /// The unique identifier of the group being associated with the user.
    var groupId: String
    
    /// Custom traits or attributes associated with the group.
    var traits: CodableCollection?

    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    var userIdentity: UserIdentity?
    
    /**
     Initializes a `GroupEvent` with the specified group identifier, traits, and options and user identity values.

     - Parameters:
        - groupId: The unique identifier of the group being associated with the user.
        - traits: Custom traits or attributes associated with the group. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to an empty instance of `RudderOption`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to a empty instance of `UserIdentity`.

     This initializer also processes and includes default values, such as default integrations and context if they are not provided.
     */
    init(groupId: String, traits: RudderTraits? = nil, options: RudderOption? = RudderOption(), userIdentity: UserIdentity = UserIdentity()) {
        self.groupId = groupId
        self.traits = CodableCollection(dictionary: traits)
        self.userIdentity = userIdentity
        self.options = options
        
        self.addDefaultValues()
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
        case groupId
        case traits
        case userId
    }
}
