//
//  ObjCTrackEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 31/07/25.
//

import Foundation

// MARK: - ObjCTrackEvent
/**
 A class that provides an Objective-C compatible interface to the internal `TrackEvent` model.
 
 Useful for exposing track event data to Objective-C codebases, allowing manipulation
 of event name, properties, and other track-specific metadata.
 */
@objc(RSSTrackEvent)
public class ObjCTrackEvent: ObjCEvent {
    
    /**
     The underlying Swift `TrackEvent` instance.
     */
    private var trackEvent: TrackEvent {
        get { 
            guard let trackEvent = event as? TrackEvent else {
                fatalError("ObjCTrackEvent should only be initialized with TrackEvent instances")
            }
            return trackEvent
        }
        set { event = newValue }
    }
    
    /**
     Initializes an `ObjCTrackEvent` with the given `TrackEvent`.
     
     - Parameter event: The underlying Swift track event model to wrap.
     */
    init(event: TrackEvent) {
        super.init(event: event)
    }
    
    /**
     Initializes an `ObjCTrackEvent` with the specified event name, properties, and options.
     
     - Parameters:
        - eventName: The name of the event being tracked.
        - properties: Additional properties or metadata associated with the event. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(eventName: String, properties: [String: Any]? = nil, options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftProperties = properties?.objCSanitized
        let swiftUserIdentity = userIdentity?.userIdentity
        
        let trackEvent = TrackEvent(
            event: eventName,
            properties: swiftProperties,
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: trackEvent)
    }

    /**
     Convenience initializer for creating a track event with just an event name.
     
     - Parameter eventName: The name of the event being tracked.
     */
    @objc
    public convenience init(eventName: String) {
        self.init(eventName: eventName, properties: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a track event with an event name and properties.
     
     - Parameters:
        - eventName: The name of the event being tracked.
        - properties: Additional properties or metadata associated with the event.
     */
    @objc
    public convenience init(eventName: String, properties: [String: Any]) {
        self.init(eventName: eventName, properties: properties, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a track event with an event name and options.
     
     - Parameters:
        - eventName: The name of the event being tracked.
        - options: Additional tracking options.
     */
    @objc
    public convenience init(eventName: String, options: RudderOption) {
        self.init(eventName: eventName, properties: nil, options: options, userIdentity: nil)
    }

    // MARK: - Objective-C Compatible Properties

    /**
     The name of the event being tracked.
     */
    @objc public var eventName: String {
        get { trackEvent.event }
        set { trackEvent.event = newValue }
    }

    /**
     Additional properties or metadata for the event.
     */
    @objc public var properties: [String: Any]? {
        get {
            trackEvent.properties?.dictionary?.rawDictionary
        }
        set {
            guard let dict = newValue?.objCSanitized else { 
                trackEvent.properties = nil
                return 
            }
            trackEvent.properties = CodableCollection(dictionary: dict)
        }
    }

    /**
     Custom options for the event, including integrations and context.
     */
    @objc public var options: RudderOption? {
        get { trackEvent.options }
        set { trackEvent.options = newValue }
    }

    /**
     The user's identity information associated with the event.
     */
    @objc public var userIdentity: ObjCUserIdentity? {
        get { 
            guard let swiftUserIdentity = trackEvent.userIdentity else { return nil }
            return ObjCUserIdentity(userIdentity: swiftUserIdentity)
        }
        set { 
            trackEvent.userIdentity = newValue?.userIdentity 
        }
    }
}
