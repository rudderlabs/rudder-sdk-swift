//
//  ObjCAliasEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 01/08/25.
//

import Foundation

// MARK: - ObjCAliasEvent
/**
 A class that provides an Objective-C compatible interface to the internal `AliasEvent` model.
 
 Useful for exposing alias event data to Objective-C codebases, allowing manipulation
 of user identifier linking and other alias-specific metadata.
 */
@objc(RSSAliasEvent)
public class ObjCAliasEvent: ObjCEvent {
    
    /**
     The underlying Swift `AliasEvent` instance.
     */
    private var aliasEvent: AliasEvent {
        get {
            guard let aliasEvent = event as? AliasEvent else {
                fatalError("ObjCAliasEvent should only be initialized with AliasEvent instances")
            }
            return aliasEvent
        }
        set { event = newValue }
    }
    
    /**
     Initializes an `ObjCAliasEvent` with the given `AliasEvent`.
     
     - Parameter event: The underlying Swift alias event model to wrap.
     */
    init(event: AliasEvent) {
        super.init(event: event)
    }
    
    /**
     Initializes an `ObjCAliasEvent` with the specified previous identifier, options, and user identity.
     
     - Parameters:
        - previousId: The existing identifier for the user that is being linked to a new identifier. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(previousId: String, options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftUserIdentity = userIdentity?.userIdentity
                
        let aliasEvent = AliasEvent(
            previousId: previousId,
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: aliasEvent)
    }

    /**
     Convenience initializer for creating an alias event with a previous ID.
     
     - Parameters:
        - previousId: The previous user ID.
     */
    @objc
    public convenience init(previousId: String) {
        self.init(previousId: previousId, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating an alias event with a previous ID and options.
     
     - Parameters:
        - previousId: The previous user ID.
        - options: Custom options for the event.
     */
    @objc
    public convenience init(previousId: String, options: RudderOption) {
        self.init(previousId: previousId, options: options, userIdentity: nil)
    }

    // MARK: - Objective-C Compatible Properties

    /**
     The previous user identifier that the new identifier is linked to.
     */
    @objc public var previousId: String {
        get { aliasEvent.previousId }
        set { aliasEvent.previousId = newValue }
    }

    /**
     Custom options for the event, including integrations and context.
     */
    @objc public var options: RudderOption? {
        get { aliasEvent.options }
        set { aliasEvent.options = newValue }
    }

    /**
     The user's identity information associated with the event.
     */
    @objc public var userIdentity: ObjCUserIdentity? {
        get {
            guard let swiftUserIdentity = aliasEvent.userIdentity else { return nil }
            return ObjCUserIdentity(userIdentity: swiftUserIdentity)
        }
        set {
            aliasEvent.userIdentity = newValue?.userIdentity
        }
    }
}
