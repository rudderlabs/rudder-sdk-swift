//
//  ObjCGroupEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 01/08/25.
//

import Foundation

// MARK: - ObjCGroupEvent
/**
 A class that provides an Objective-C compatible interface to the internal `GroupEvent` model.
 
 Useful for exposing group event data to Objective-C codebases, allowing manipulation
 of group ID, traits, and other group-specific metadata.
 */
@objc(RSSGroupEvent)
public class ObjCGroupEvent: ObjCEvent {
    
    /**
     The underlying Swift `GroupEvent` instance.
     */
    private var groupEvent: GroupEvent {
        get {
            guard let groupEvent = event as? GroupEvent else {
                fatalError("ObjCGroupEvent should only be initialized with GroupEvent instances")
            }
            return groupEvent
        }
        set { event = newValue }
    }
    
    /**
     Initializes an `ObjCGroupEvent` with the given `GroupEvent`.
     
     - Parameter event: The underlying Swift group event model to wrap.
     */
    init(event: GroupEvent) {
        super.init(event: event)
    }
    
    /**
     Initializes an `ObjCGroupEvent` with the specified group ID, traits, and options.
     
     - Parameters:
        - groupId: The unique identifier of the group being associated with the user.
        - traits: Custom traits or attributes associated with the group. Defaults to `nil`.
        - options: Custom options for the event, including integrations and context. Defaults to `nil`.
        - userIdentity: The user's identity information. Defaults to `nil`.
     */
    @objc
    public init(groupId: String, traits: [String: Any]? = nil, options: RudderOption? = nil, userIdentity: ObjCUserIdentity? = nil) {
        let swiftTraits = traits?.objCSanitized
        let swiftUserIdentity = userIdentity?.userIdentity
        
        let groupEvent = GroupEvent(
            groupId: groupId,
            traits: swiftTraits,
            options: options,
            userIdentity: swiftUserIdentity
        )
        
        super.init(event: groupEvent)
    }

    /**
     Convenience initializer for creating a group event with just a group ID.
     
     - Parameter groupId: The unique identifier of the group being associated with the user.
     */
    @objc
    public convenience init(groupId: String) {
        self.init(groupId: groupId, traits: nil, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a group event with a group ID and traits.
     
     - Parameters:
        - groupId: The unique identifier of the group being associated with the user.
        - traits: Custom traits or attributes associated with the group.
     */
    @objc
    public convenience init(groupId: String, traits: [String: Any]) {
        self.init(groupId: groupId, traits: traits, options: nil, userIdentity: nil)
    }

    /**
     Convenience initializer for creating a group event with a group ID and options.
     
     - Parameters:
        - groupId: The unique identifier of the group being associated with the user.
        - options: Additional options for the event.
     */
    @objc
    public convenience init(groupId: String, options: RudderOption) {
        self.init(groupId: groupId, traits: nil, options: options, userIdentity: nil)
    }

    // MARK: - Objective-C Compatible Properties

    /**
     The unique identifier of the group being associated with the user.
     */
    @objc public var groupId: String {
        get { groupEvent.groupId }
        set { groupEvent.groupId = newValue }
    }

    /**
     Custom options for the event, including integrations and context.
     */
    @objc public var options: RudderOption? {
        get { groupEvent.options }
        set { groupEvent.options = newValue }
    }

    /**
     The user's identity information associated with the event.
     */
    @objc public var userIdentity: ObjCUserIdentity? {
        get {
            guard let swiftUserIdentity = groupEvent.userIdentity else { return nil }
            return ObjCUserIdentity(userIdentity: swiftUserIdentity)
        }
        set {
            groupEvent.userIdentity = newValue?.userIdentity
        }
    }
}
