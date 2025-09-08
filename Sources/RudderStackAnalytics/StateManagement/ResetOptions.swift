//
//  ResetOptions.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 08/09/25.
//

import Foundation

/**
 Class representing options for resetting user data in the analytics SDK.
 */
public class ResetOptions {
    
    /** An instance of `ResetEntries` specifying which data to reset. */
    public let entries: ResetEntries
    
    /**
     Initializes a new instance of `ResetOptions`.
     
     - Parameters:
       - entries: An instance of `ResetEntries` specifying which data to reset. Default is a new instance with all entries set to `true`.
     */
    public init(entries: ResetEntries = ResetEntries()) {
        self.entries = entries
    }
}

/**
 Class representing specific entries to reset during a user data reset operation.
 */
public class ResetEntries {

    /** A Boolean indicating whether to reset the anonymous ID. Default is `true`. */
    public let anonymousId: Bool
    
    /** A Boolean indicating whether to reset the user ID. Default is `true`. */
    public let userId: Bool

    /** A Boolean indicating whether to reset user traits. Default is `true`. */
    public let traits: Bool
    
    /** A Boolean indicating whether to reset session information. Default is `true`. */
    public let session: Bool

    /**
     Initializes a new instance of `ResetEntries`.
     
     - Parameters:
       - anonymousId: Whether to reset the anonymous ID. Default is `true`.
       - userId: Whether to reset the user ID. Default is `true`.
       - traits: Whether to reset user traits. Default is `true`.
       - session: Whether to reset session information. Default is `true`.
     */
    public init(anonymousId: Bool = true, userId: Bool = true, traits: Bool = true, session: Bool = true) {
        self.anonymousId = anonymousId
        self.userId = userId
        self.traits = traits
        self.session = session
    }
}
