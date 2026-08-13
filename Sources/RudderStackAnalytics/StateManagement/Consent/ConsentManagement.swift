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
 
 `initialized` is `false` until consent values have actually been supplied
 (via configuration or `setConsent(_:)`). While uninitialized, consent
 evaluation fails open — no destination is blocked.
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
     
     Consent IDs are trimmed and empties dropped. The state is considered
     initialized only when enabled and at least one non-empty list was supplied.
     */
    static func initialState(_ configuration: ConsentManagementConfiguration) -> ConsentManagement {
        let allowed = Self.normalized(configuration.allowedConsentIds)
        let denied = Self.normalized(configuration.deniedConsentIds)
        return ConsentManagement(
            enabled: configuration.enabled,
            provider: configuration.provider,
            allowedConsentIds: allowed,
            deniedConsentIds: denied,
            initialized: configuration.enabled && !(allowed.isEmpty && denied.isEmpty)
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
