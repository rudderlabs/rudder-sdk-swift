//
//  ConsentManagementConfiguration.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - ConsentManagementConfiguration
/**
 A configuration class for managing consent settings.
 */
@objc(RSSConsentManagementConfiguration)
public class ConsentManagementConfiguration: NSObject {
    /**
     A flag indicating whether consent management is enabled.
     */
    var enabled: Bool
    
    /**
     The consent provider. Currently only `.custom` is supported.
     */
    var provider: ConsentManagementProvider
    
    /**
     Consent category IDs the user has granted.
     */
    var allowedConsentIds: [String]
    
    /**
     Consent category IDs the user has denied.
     */
    var deniedConsentIds: [String]
    
    public init(
        enabled: Bool = Constants.defaultConfig.consentManagementEnabled,
        provider: ConsentManagementProvider = .custom,
        allowedConsentIds: [String] = [],
        deniedConsentIds: [String] = []
    ) {
        self.enabled = enabled
        self.provider = provider
        self.allowedConsentIds = allowedConsentIds
        self.deniedConsentIds = deniedConsentIds
    }
}

// MARK: - ConsentManagementProvider
/**
 Supported consent management providers.
 */
@objc(RSSConsentManagementProvider)
public enum ConsentManagementProvider: Int {
    case custom
    
    /** The wire value stamped into `context.consentManagement.provider`. */
    var value: String {
        switch self {
        case .custom: return "custom"
        }
    }
}
