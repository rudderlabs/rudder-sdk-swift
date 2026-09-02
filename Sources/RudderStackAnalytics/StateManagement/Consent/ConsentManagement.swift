//
//  ConsentManagement.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Foundation

// MARK: - ConsentManagement
/**
 A reactive state model holding the current consent values.
 
 The two consent ID lists are never both empty while `enabled` is `true`: a configuration that enables consent management without supplying either list is a configuration error, and the state is built inactive so the feature behaves as if it had never been enabled.
 */
struct ConsentManagement: Equatable {
    var enabled: Bool = false
    var provider: ConsentManagementProvider = .custom
    var allowedConsentIds: [String] = []
    var deniedConsentIds: [String] = []
    var initialized: Bool = false
}

// MARK: - Normalization
extension ConsentManagement {
    /**
     Builds the initial consent state from the load-time configuration.
     
     Consent IDs are trimmed and empties dropped. Enabling consent management without supplying either list is a configuration error: the state is built inactive, so the feature behaves exactly as if it had never been enabled.
     */
    static func initialState(_ configuration: ConsentManagementConfiguration) -> ConsentManagement {
        let allowed = Self.normalized(configuration.allowedConsentIds)
        let denied = Self.normalized(configuration.deniedConsentIds)
        let active = configuration.enabled && !(allowed.isEmpty && denied.isEmpty)
        
        return ConsentManagement(
            enabled: active,
            provider: configuration.provider,
            allowedConsentIds: allowed,
            deniedConsentIds: denied,
            initialized: active
        )
    }
    
    /**
     Trims whitespace from each consent ID and drops the resulting empties.
     */
    static func normalized(_ consentIds: [String]) -> [String] {
        consentIds
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
