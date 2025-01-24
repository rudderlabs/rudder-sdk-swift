//
//  Message.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

// MARK: - Message
/**
 A base protocol for all events in the analytics system.

 The `Message` protocol defines the common properties and behaviors required for all types of event messages.
 It conforms to the `Codable` protocol, enabling easy encoding and decoding for storage or network transmission.
 */
public protocol Message: Codable {

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
    var integrations: [String: Bool]? { get set }

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
     A unique identifier for the message.
     
     This ensures each message can be tracked individually.
     */
    var messageId: String { get set }

    /**
     The original timestamp when the event occurred, in ISO 8601 format.
     */
    var originalTimeStamp: String { get set }
    
    /**
     The identity values of the user associated with the event.
     */
    var userIdentity: UserIdentity? { get set }
}

extension Message {

    /**
     Adds default or standard values to the `Message` object.

     It ensures that each event has consistent base data.
     */
    mutating func addDefaultValues() {
        self.channel = Constants.defaultChannel
        self.sentAt = Constants.defaultSentAtPlaceholder
    }
    
    func updateEventData() -> Message {
        var mutableSelf: Message = self
        
        mutableSelf.anonymousId = self.userIdentity?.anonymousId
        mutableSelf.userId = self.userIdentity?.userId.isEmpty == true ? nil : self.userIdentity?.userId
        
        if var traits = self.userIdentity?.traits, let userId = mutableSelf.userId {
            traits["userId"] = userId
            mutableSelf = mutableSelf.addToContext(info: ["traits": traits])
        }
        
        if let externalIds = self.userIdentity?.externalIds, !externalIds.isEmpty {
            mutableSelf = mutableSelf.addToContext(info: ["externalId": externalIds.compactMap { $0.dictionary }])
        }
        
        return mutableSelf
    }

    /**
     Appends additional context information to the `Message` payload.

     This method takes a dictionary of key-value pairs and merges it with the existing `context` property. The values are wrapped in `AnyCodable` to ensure type compatibility.

     - Parameter info: A dictionary containing context information to append.
     - Returns: A new `Message` instance with the updated context.

     - Note: If the `context` property is `nil`, it is initialized with the provided context.
     */
    public func addToContext(info: [String: Any]) -> Message {
        var mutableSelf = self
        mutableSelf.context = (mutableSelf.context ?? [:]) + info.mapValues { AnyCodable($0) }
        return mutableSelf
    }
}

// MARK: - EventType
/**
 Represents the type of events supported by the analytics system.

 The `EventType` enum defines various event types such as `identify`, `track`, `screen`, `group`, and `flush`.
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

    /// Represents a "flush" event.
    case flush

    /**
     A computed property that returns a human-readable label for the event type.

     - Returns: The event type string with its first letter capitalized.
     */
    public var label: String {
        return rawValue.capitalized
    }
}
