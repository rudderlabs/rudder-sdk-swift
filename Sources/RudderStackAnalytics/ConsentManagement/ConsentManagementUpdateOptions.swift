//
//  ConsentManagementUpdateOptions.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - ConsentManagementUpdateOptions
/**
 Options for updating consent at runtime via `Analytics.setConsent(_:)`.

 The supplied lists fully replace the current consent state. Omitted lists default
 to empty, which clears the corresponding values.
 */
@objc(RSSConsentManagementUpdateOptions)
public class ConsentManagementUpdateOptions: NSObject {
    /**
     Consent category IDs the user has granted.
     */
    var allowedConsentIds: [String]

    /**
     Consent category IDs the user has denied.
     */
    var deniedConsentIds: [String]

    /**
     Initializes a new consent update options instance.

     - Parameters:
        - allowedConsentIds: Consent category IDs the user has granted. Defaults to empty.
        - deniedConsentIds: Consent category IDs the user has denied. Defaults to empty.
     */
    public init(
        allowedConsentIds: [String] = [],
        deniedConsentIds: [String] = []
    ) {
        self.allowedConsentIds = allowedConsentIds
        self.deniedConsentIds = deniedConsentIds
    }
}
