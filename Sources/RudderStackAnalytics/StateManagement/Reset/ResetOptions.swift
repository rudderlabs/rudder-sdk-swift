//
//  ResetOptions.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 08/09/25.
//

import Foundation

// MARK: - ResetOptions
/**
 Configuration class for customizing user data reset behavior in the analytics SDK.
 
 Encapsulates reset preferences through ResetEntries, enabling selective clearing of user identity components while maintaining backward compatibility with default full reset behavior.
 */
@objc(RSSResetOptions)
public class ResetOptions: NSObject {
    
    /** An instance of `ResetEntries` specifying which data to reset. */
    @objc public let entries: ResetEntries
    
    /**
     Initializes a new instance of `ResetOptions`.
     
     - Parameters:
       - entries: An instance of `ResetEntries` specifying which data to reset. Default is a new instance with all entries set to `true`.
     */
    public init(entries: ResetEntries = ResetEntries()) {
        self.entries = entries
    }
}
