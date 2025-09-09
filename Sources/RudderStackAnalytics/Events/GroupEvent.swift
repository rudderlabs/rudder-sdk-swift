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
public struct GroupEvent: Event {
    
    /// The type of the event, defaulting to `.group`.
    public var type: EventType = .group
    
    /// A unique identifier for the event.
    public var messageId: String = .randomUUIDString
    
    /// The timestamp of when the event occurred, defaulting to the current time.
    public var originalTimestamp: String = .currentTimeStamp
    
    /// The anonymous identifier for the user associated with the event.
    public var anonymousId: String?
    
    /// The channel through which the event was sent.
    public var channel: String?
    
    /// A dictionary of integration settings for the event.
    public var integrations: [String: AnyCodable]?
    
    /// The timestamp of when the event was sent.
    public var sentAt: String?
    
    /// Additional context information for the event, provided as a dictionary.
    public var context: [String: AnyCodable]?
    
    /// The unique identifier for the user.
    public var userId: String?
    
    /// The unique identifier of the group being associated with the user.
    public var groupId: String
    
    /// Custom traits or attributes associated with the group.
    public var traits: CodableCollection?

    /// Holds the associated values for an event.
    public var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    public var userIdentity: UserIdentity?
    
    /**
     Initializes a `GroupEvent` with the specified group identifier, traits, and options and user identity values.

     - Parameters:
        - groupId: The unique identifier of the group being associated with the user.
        - traits: Custom traits or attributes associated with the group. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to `nil`.

     This initializer also processes and includes default values, such as default integrations and context if they are not provided.
     */
    public init(groupId: String, traits: Traits? = nil, options: RudderOption? = nil, userIdentity: UserIdentity? = nil) {
        self.groupId = groupId
        self.traits = CodableCollection(dictionary: traits)
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
        case groupId
        case traits
        case userId
    }
}
