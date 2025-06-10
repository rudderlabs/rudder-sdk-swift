//
//  ObjCEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/05/25.
//

import Foundation

// MARK: - ObjCEvent
/**
 A class that provides an Objective-C compatible interface to the internal `Event` model.
 
 Useful for exposing analytics event data to Objective-C codebases, allowing manipulation
 of event metadata, integrations, context, traits, and other properties.
 */
@objc(RSAEvent)
public class ObjCEvent: NSObject {
    /**
     The underlying Swift `Event` instance.
     */
    internal var event: Event

    /**
     Initializes an `ObjCEvent` with the given `Event`.
     
     - Parameter event: The underlying Swift event model to wrap.
     */
    init(event: Event) {
        self.event = event
    }

    // MARK: - Objective-C Compatible Properties

    /**
     A unique identifier for anonymous users.
     */
    @objc public var anonymousId: String? {
        get { event.anonymousId }
        set { event.anonymousId = newValue }
    }

    /**
     The user identifier, if known.
     */
    @objc public var userId: String? {
        get { event.userId }
        set { event.userId = newValue }
    }

    /**
     The originating channel of the event.
     */
    @objc public var channel: String? {
        get { event.channel }
        set { event.channel = newValue }
    }
    
    /**
     A dictionary of integration-specific configuration for this event.
     */
    @objc public var integrations: [String: Any]? {
        get {
            event.integrations?.mapValues { $0.value as Any } as? [String: Any]
        }
        set {
            guard let dict = newValue?.objCSanitized else { return }
            event.integrations = dict.mapValues { AnyCodable($0) }
        }
    }
    
    /**
     A dictionary of context information providing environmental details for the event.
     */
    @objc public var context: [String: Any]? {
        get {
            event.context?.mapValues { $0.value as Any } as? [String: Any]
        }
        set {
            guard let dict = newValue?.objCSanitized else { return }
            event.context = dict.mapValues { AnyCodable($0) }
        }
    }
    
    /**
     Arbitrary user traits, either as an array or dictionary.
     */
    @objc public var traits: Any? {
        get {
            if let array = event.traits?.array {
                return array.map { $0.value } as [Any]
            } else if let dict = event.traits?.dictionary {
                return dict.mapValues { $0.value } as [String: Any]
            }
            return nil
        }
        set {
            if let array = newValue as? [Any] {
                event.traits = CodableCollection(array: array.objCSanitized)
            } else if let dict = newValue as? [String: Any] {
                event.traits = CodableCollection(dictionary: dict.objCSanitized)
            } else {
                return
            }
        }
    }

    /**
     The type of event (e.g., track, identify, screen).
     */
    @objc public var type: ObjCEventType {
        get { event.type.objcValue }
        set {
            if let eventType = EventType(objcType: newValue) {
                event.type = eventType
            }
        }
    }

    /**
     A unique identifier for this message.
     */
    @objc public var messageId: String {
        get { event.messageId }
        set { event.messageId = newValue }
    }

    /**
     The original timestamp of when the event occurred.
     */
    public var originalTimestamp: String {
        get { event.originalTimestamp }
        set { event.originalTimestamp = newValue }
    }

    /**
     The timestamp for when the event was sent.
     */
    @objc public var sentAt: String? {
        get { event.sentAt }
        set { event.sentAt = newValue }
    }
}

// MARK: - ObjCEventType
/**
 An Objective-C compatible representation of `EventType`.

 Each case corresponds to a type of event that can be tracked.
 */
@objc(RSAEventType)
public enum ObjCEventType: Int {
    /** Represents an `identify` event. */
    case identify = 1

    /** Represents a `track` event. */
    case track

    /** Represents a `screen` event. */
    case screen

    /** Represents a `group` event. */
    case group

    /** Represents an `alias` event. */
    case alias
}

// MARK: - EventType

extension EventType {
    /**
     Initializes a Swift `EventType` from an Objective-C compatible `ObjCEventType`.

     - Parameter objcType: The Objective-C representation of the event type.
     */
    init?(objcType: ObjCEventType) {
        switch objcType {
        case .identify: self = .identify
        case .track: self = .track
        case .screen: self = .screen
        case .group: self = .group
        case .alias: self = .alias
        @unknown default: return nil
        }
    }

    /**
     Returns the Objective-C compatible representation of the `EventType`.

     - Returns: An equivalent `ObjCEventType` for use in Objective-C code.
     */
    var objcValue: ObjCEventType {
        return switch self {
        case .identify: .identify
        case .track: .track
        case .screen: .screen
        case .group: .group
        case .alias: .alias
        }
    }
}
