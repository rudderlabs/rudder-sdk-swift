//
//  ObjCUserIdentity.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 31/07/25.
//

import Foundation

// MARK: - ObjCUserIdentity
/**
 A class that provides an Objective-C compatible interface to the internal `UserIdentity` model.
 
 Useful for exposing user identity data to Objective-C codebases, allowing manipulation
 of anonymous ID, user ID, and traits properties.
 */
@objc(RSSUserIdentity)
public class ObjCUserIdentity: NSObject {
    /**
     The underlying Swift `UserIdentity` instance.
     */
    internal var userIdentity: UserIdentity

    /**
     Initializes an `ObjCUserIdentity` with the given `UserIdentity`.
     
     - Parameter userIdentity: The underlying Swift user identity model to wrap.
     */
    init(userIdentity: UserIdentity) {
        self.userIdentity = userIdentity
    }

    /**
     Initializes an `ObjCUserIdentity` with default values.
     */
    @objc
    public override init() {
        self.userIdentity = UserIdentity()
        super.init()
    }

    /**
     Initializes an `ObjCUserIdentity` with the specified identifiers and traits.
     
     - Parameters:
       - anonymousId: A unique identifier for the user when they are not logged in.
       - userId: The identifier for the user when they are logged in.
       - traits: A dictionary of user-specific traits for storing additional metadata about the user.
     */
    @objc
    public init(anonymousId: String, userId: String, traits: [String: Any]?) {
        self.userIdentity = UserIdentity(anonymousId: anonymousId, userId: userId, traits: traits?.objCSanitized ?? Traits())
        super.init()
    }

    // MARK: - Objective-C Compatible Properties

    /**
     A unique identifier for the user when they are not logged in.
     */
    @objc public var anonymousId: String {
        get { userIdentity.anonymousId }
        set { userIdentity.anonymousId = newValue }
    }

    /**
     The identifier for the user when they are logged in.
     */
    @objc public var userId: String {
        get { userIdentity.userId }
        set { userIdentity.userId = newValue }
    }

    /**
     A dictionary of user-specific traits, used to store additional metadata about the user.
     */
    @objc public var traits: [String: Any] {
        get { userIdentity.traits }
        set { userIdentity.traits = newValue.objCSanitized }
    }
}
