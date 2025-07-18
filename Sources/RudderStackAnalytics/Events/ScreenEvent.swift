//
//  ScreenEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 31/12/24.
//

import Foundation

// MARK: - ScreenEvent

/**
 Represents a screen event in the analytics system.

 This struct conforms to the `Event` protocol and is used to track when a user navigates to a specific screen or page in the application.

 - Conforms to: `Event`
 */
struct ScreenEvent: Event {
    
    /// The type of the event, defaulting to `.screen`.
    var type: EventType = .screen
    
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
    
    /// The unique identifier for the user.
    var userId: String?
    
    /// The name of the screen or page being tracked.
    var event: String
    
    /// The category of the screen, if any.
    var category: String?
    
    /// Additional properties or metadata for the screen event.
    var properties: CodableCollection?

    /// Holds the associated values for an event.
    var options: RudderOption?
    
    /// The identity values of the user associated with the event.
    var userIdentity: UserIdentity?
    
    /**
     Initializes a `ScreenEvent` with the specified screen name, category, properties, options and user identity values.

     - Parameters:
        - screenName: The name of the screen or page being tracked.
        - category: The category of the screen, if applicable. Defaults to `nil`.
        - properties: Additional properties or metadata associated with the screen event. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information, represented as `UserIdentity`. Defaults to `nil`.

     This initializer also processes and includes default properties such as the screen name and category in the event's properties, if they are provided.
     */
    init(screenName: String, category: String? = nil, properties: Properties? = nil, options: RudderOption? = nil, userIdentity: UserIdentity? = nil) {
        self.event = screenName
        
        var updatedProperties = properties ?? Properties()
        updatedProperties["category"] = category?.isEmpty ?? true ? nil : category
        updatedProperties["name"] = screenName.isEmpty ? nil : screenName
        
        self.properties = CodableCollection(dictionary: updatedProperties)
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
        case category
        case properties
        case userId
    }
}
