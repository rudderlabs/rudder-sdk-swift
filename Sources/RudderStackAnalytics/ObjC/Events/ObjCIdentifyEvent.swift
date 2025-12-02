//
//  ObjCIdentifyEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 01/08/25.
//

import Foundation

// MARK: - ObjCIdentifyEvent
/**
 A class that provides an Objective-C compatible interface to the internal `IdentifyEvent` model.
 
 Useful for exposing identify event data to Objective-C codebases, allowing manipulation
 of user traits and other identify-specific metadata.
 */
@objc(RSSIdentifyEvent)
public class ObjCIdentifyEvent: ObjCEvent {
    
    /**
     The underlying Swift `IdentifyEvent` instance.
     */
    private var identifyEvent: IdentifyEvent {
        get {
            guard let identifyEvent = event as? IdentifyEvent else {
                fatalError("ObjCIdentifyEvent should only be initialized with IdentifyEvent instances")
            }
            return identifyEvent
        }
        set { event = newValue }
    }
    
    /**
     Initializes an `ObjCIdentifyEvent` with the given `IdentifyEvent`.
     
     - Parameter event: The underlying Swift identify event model to wrap.
     */
    init(event: IdentifyEvent) {
        super.init(event: event)
    }
    
    /**
     Initializes an `ObjCIdentifyEvent` with the specified options and user identity.
     
     - Parameters:
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftUserIdentity = userIdentity?.userIdentity
        
        let identifyEvent = IdentifyEvent(
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: identifyEvent)
    }

    /**
     Convenience initializer for creating an identify event with default values.
     */
    @objc
    public convenience init() {
        self.init(options: nil, userIdentity: nil)
    }

    // MARK: - Objective-C Compatible Properties

    /**
     Custom options for the event, including integrations and context.
     */
    @objc public var options: RudderOption? {
        get { identifyEvent.options }
        set { identifyEvent.options = newValue }
    }

    /**
     The user's identity information associated with the event.
     */
    @objc public var userIdentity: ObjCUserIdentity? {
        get {
            guard let swiftUserIdentity = identifyEvent.userIdentity else { return nil }
            return ObjCUserIdentity(userIdentity: swiftUserIdentity)
        }
        set {
            identifyEvent.userIdentity = newValue?.userIdentity
        }
    }
}
