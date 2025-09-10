//
//  ResetEntries.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 09/09/25.
//

import Foundation

// MARK: - ResetEntries
/**
 Class representing specific entries to reset during a user data reset operation.
 
 Provides granular control over which user identity components should be cleared, allowing selective reset of anonymous ID, user ID, traits, and session information.
 */
@objc(RSSResetEntries)
public class ResetEntries: NSObject {

    /** A Boolean indicating whether to reset the anonymous ID. Default is `true`. */
    @objc public let anonymousId: Bool
    
    /** A Boolean indicating whether to reset the user ID. Default is `true`. */
    @objc public let userId: Bool

    /** A Boolean indicating whether to reset user traits. Default is `true`. */
    @objc public let traits: Bool
    
    /** A Boolean indicating whether to reset session information. Default is `true`. */
    @objc public let session: Bool

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
