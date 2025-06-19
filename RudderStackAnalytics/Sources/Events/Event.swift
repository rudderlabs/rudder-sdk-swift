//
//  Event.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - Event
/**
 A base protocol for all events in the analytics system.

 The `Event` protocol defines the common properties and behaviors required for all types of incoming events.
 It conforms to the `Codable` protocol, enabling easy encoding and decoding for storage or network transmission.
 */
public protocol Event: Codable {

    // MARK: - Properties

    /**
     The unique identifier for an anonymous user.
     
     This property is optional and may be used to track events for anonymous users.
     */
    var anonymousId: String? { get set }

    /**
     The unique identifier for the user.
     */
    var userId: String? { get set }
    
    /**
     The channel through which the event was triggered.
     */
    var channel: String? { get set }

    /**
     A dictionary specifying the integrations involved in this event.
    */
    var integrations: [String: AnyCodable]? { get set }

    /**
     The timestamp when the event was sent, in ISO 8601 format.
     */
    var sentAt: String? { get set }

    /**
     Additional contextual information associated with the event.
     
     The context is represented as a dictionary of key-value pairs, where values are of type `AnyCodable`.
     */
    var context: [String: AnyCodable]? { get set }

    /**
     A collection of traits or attributes associated with the event.
     
     These traits can be user properties or additional metadata.
     */
    var traits: CodableCollection? { get set }

    /**
     The type of event, defined by the `EventType` enumeration.
     */
    var type: EventType { get set }

    /**
     A unique identifier for the event.
     
     This ensures each event can be tracked individually.
     */
    var messageId: String { get set }

    /**
     The original timestamp when the event occurred, in ISO 8601 format.
     */
    var originalTimestamp: String { get set }
    
    /**
     Holds the associated values for an event.
     */
    var options: RudderOption? { get set }
    
    /**
     The identity values of the user associated with the event.
     */
    var userIdentity: UserIdentity? { get set }
}

extension Event {

    /**
     Adds default or standard values to the `Event` object.

     It ensures that each event has consistent base data.
     */
    mutating func addDefaultValues() {
        self.channel = Constants.payload.channel
        self.sentAt = Constants.payload.sentAtPlaceholder
    }
    
    /**
     Updates the event data with user identity information.

     - Returns: A `Event` object with the updated event data.
     */
    func updateEventData() -> Event {
        var mutableSelf: Event = self
        
        mutableSelf.anonymousId = self.userIdentity?.anonymousId
        mutableSelf.userId = self.userIdentity?.userId.isEmpty == true ? nil : self.userIdentity?.userId
    
        if let traits = self.userIdentity?.traits, !traits.isEmpty {
            mutableSelf = mutableSelf.addToContext(info: ["traits": traits])
        }
        
        if let integrations = self.options?.integrations, !integrations.isEmpty {
            mutableSelf = mutableSelf.addToIntegrations(info: integrations)
        }
                
        if let customContext = self.options?.customContext, !customContext.isEmpty {
            mutableSelf = mutableSelf.addToContext(info: customContext)
        }
        
        if let externalIds = self.options?.externalIds, !externalIds.isEmpty {
            mutableSelf = mutableSelf.addExternalIds(info: externalIds)
        }
        
        return mutableSelf
    }

    /**
     Appends additional context information to the `Event` payload.

     This method takes a dictionary of key-value pairs and merges it with the existing `context` property. The values are wrapped in `AnyCodable` to ensure type compatibility.

     - Parameter info: A dictionary containing context information to append.
     - Returns: A new `Event` instance with the updated context.

     - Note: If the `context` property is `nil`, it is initialized with the provided context.
     */
    func addToContext(info: [String: Any]) -> Event {
        var mutableSelf = self
        mutableSelf.context = (mutableSelf.context ?? [:]) + info.mapValues { AnyCodable($0) }
        return mutableSelf
    }
    
    /**
     Appends integration information to the `Event` payload.

     This method takes a dictionary of key-value pairs and merges it with the existing `integrations` property. The values are wrapped in `AnyCodable` to ensure type compatibility.

     - Parameter info: A dictionary containing integration information to append.
     - Returns: A new `Event` instance with the updated context.
     
     */
    func addToIntegrations(info: [String: Any]) -> Event {
        var mutableSelf = self
        mutableSelf.integrations = (mutableSelf.integrations ?? [:]) + info.mapValues { AnyCodable($0) }
        return mutableSelf
    }
    
    /**
     Appends external id information to the `Event` payload.

     This method takes a array of `ExternalId`s and merges it with the existing `context` property. The values are wrapped in `AnyCodable` to ensure type compatibility.

     - Parameter info: A array containing `ExternalId` information to append.
     - Returns: A new `Event` instance with the updated context.
     
     */
    func addExternalIds(info: [ExternalId]) -> Event {
        return info.isEmpty ? self : self.addToContext(info: ["externalId": info.compactMap { $0.dictionary }])
    }
}

// MARK: - EventType
/**
 Represents the type of events supported by the analytics system.

 The `EventType` enum defines various event types such as `identify`, `track`, `screen`, `group` and `alias`.
 It conforms to `CaseIterable` for easy iteration and `Codable` for seamless encoding and decoding.
 */
public enum EventType: String, CaseIterable, Codable {

    /// Represents a "identify" event.
    case identify
    
    /// Represents a "track" event.
    case track

    /// Represents a "screen" event.
    case screen

    /// Represents a "group" event.
    case group
    
    /// Represents a "alias" event.
    case alias

    /**
     A computed property that returns a human-readable label for the event type.

     - Returns: The event type string with its first letter capitalized.
     */
    public var label: String {
        return rawValue.capitalized
    }
}
