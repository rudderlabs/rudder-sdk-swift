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
     Initializes an `ObjCIdentifyEvent` with the specified user ID, traits, options and user identity.
     
     - Parameters:
        - userId: The user ID. Defaults to `nil`.
        - traits: Custom traits or attributes for the user. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(userId: String? = nil, traits: [String: Any]? = nil, options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftUserIdentity = userIdentity?.userIdentity
        
        let identifyEvent = IdentifyEvent(
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: identifyEvent)
        
        // Set userId and traits after initialization
        if let userId = userId {
            self.userId = userId
        }
        if let traits = traits {
            self.traits = traits
        }
    }

    /**
     Convenience initializer for creating an identify event with default values.
     */
    @objc
    public convenience init() {
        self.init(userId: nil, traits: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for identifying a user by user ID.
     
     - Parameter userId: The user ID.
     */
    @objc
    public convenience init(userId: String) {
        self.init(userId: userId, traits: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for identifying a user by traits only.
     
     - Parameter traits: Traits associated with the user.
     */
    @objc
    public convenience init(traits: [String: Any]) {
        self.init(userId: nil, traits: traits, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for identifying a user by user ID and traits.
     
     - Parameters:
        - userId: The user ID.
        - traits: Traits associated with the user.
     */
    @objc
    public convenience init(userId: String, traits: [String: Any]) {
        self.init(userId: userId, traits: traits, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for identifying a user by user ID and options.
     
     - Parameters:
        - userId: The user ID.
        - options: Additional options.
     */
    @objc
    public convenience init(userId: String, options: RudderOption) {
        self.init(userId: userId, traits: nil, options: options, userIdentity: nil)
    }

    /**
     Convenience initializer for identifying a user by traits and options.
     
     - Parameters:
        - traits: Traits associated with the user.
        - options: Additional options.
     */
    @objc
    public convenience init(traits: [String: Any], options: RudderOption) {
        self.init(userId: nil, traits: traits, options: options, userIdentity: nil)
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
