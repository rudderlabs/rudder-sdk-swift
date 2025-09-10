//
//  ObjCResetEntriesBuilder.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 10/09/25.
//

import Foundation

/**
 Builder pattern class for constructing ResetEntries instances in Objective-C environments.
 
 Accommodates a fluent interface for configuring ResetEntries used in reset operations.
 */
@objc(RSSResetEntriesBuilder)
public final class ObjCResetEntriesBuilder: NSObject {
    private var anonymousId: Bool = true
    private var userId: Bool = true
    private var traits: Bool = true
    private var session: Bool = true
    
    /**
     Initializes a new builder with default values.
     */
    @objc
    public override init() {
        super.init()
    }
    
    /**
     Sets whether to reset the anonymous ID.
     
     - Parameter reset: Whether to reset the anonymous ID. Defaults to `true`.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setResetAnonymousId(_ reset: Bool) -> Self {
        self.anonymousId = reset
        return self
    }
    
    /**
     Sets whether to reset the user ID.
     
     - Parameter reset: Whether to reset the user ID. Defaults to `true`.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setResetUserId(_ reset: Bool) -> Self {
        self.userId = reset
        return self
    }
    
    /**
     Sets whether to reset the traits.
     
     - Parameter reset: Whether to reset the traits. Defaults to `true`.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setResetTraits(_ reset: Bool) -> Self {
        self.traits = reset
        return self
    }
    
    /**
     Sets whether to reset the session.
     
     - Parameter reset: Whether to reset the session. Defaults to `true`.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setResetSession(_ reset: Bool) -> Self {
        self.session = reset
        return self
    }
    
    /**
     Builds and returns a ResetEntries instance configured with the specified options.
     */
    @objc
    public func build() -> ResetEntries {
        return ResetEntries(anonymousId: anonymousId, userId: userId, traits: traits, session: session)
    }
}
