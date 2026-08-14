//
//  ConsentManagementOptions.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - ConsentManagementOptions
/**
 Options for updating consent at runtime via `Analytics.setConsent(_:)`.

 The supplied lists fully replace the current consent state. Omitted lists default
 to empty, which clears the corresponding values.
 */
@objc(RSSConsentManagementOptions)
public class ConsentManagementOptions: NSObject {
    /**
     Consent category IDs the user has granted.
     */
    var allowedConsentIds: [String]

    /**
     Consent category IDs the user has denied.
     */
    var deniedConsentIds: [String]

    /**
     Initializes an empty options instance. Both lists default to empty, which
     clears the current consent state when passed to `Analytics.setConsent(_:)`.
     */
    @objc
    public convenience override init() {
        self.init(allowedConsentIds: [], deniedConsentIds: [])
    }

    /**
     Initializes a new consent update options instance.

     - Parameters:
        - allowedConsentIds: Consent category IDs the user has granted. Defaults to empty.
        - deniedConsentIds: Consent category IDs the user has denied. Defaults to empty.
     */
    @objc
    public init(
        allowedConsentIds: [String] = [],
        deniedConsentIds: [String] = []
    ) {
        self.allowedConsentIds = allowedConsentIds
        self.deniedConsentIds = deniedConsentIds
    }
}
