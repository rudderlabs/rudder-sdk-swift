//
//  ConsentResolver.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Foundation

// MARK: - ConsentResolverConstants
struct ConsentResolverConstants {
    static let consentManagementKey = "consentManagement"
    static let providerKey = "provider"
    static let consentsKey = "consents"
    static let consentKey = "consent"
    static let resolutionStrategyKey = "resolutionStrategy"
}

// MARK: - ConsentResolutionStrategy
/**
 Strategy for matching configured consent IDs against the allowed list.

 `and`/`all` require every configured ID; `or`/`any` require at least one.
 Missing, empty, or unrecognized values normalize to `and`.
 */
enum ConsentResolutionStrategy {
    case all
    case any

    init(rawValue: String?) {
        switch rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "or", "any":
            self = .any
        default:
            self = .all
        }
    }
}

// MARK: - ConsentResolver
/**
 The single consent decision point shared by the initialization and event gates.

 A pure, stateless, fail-open resolution predicate: missing configuration,
 malformed entries, and unknown strategies all resolve to consented — gating
 must never break event delivery because of unexpected data. Only
 `allowedConsentIds` participate in matching; `deniedConsentIds` are stamped
 on events but never consulted.
 */
struct ConsentResolver {
    /**
     Resolves whether a destination is consented under the current consent state.
     
     - Parameters:
        - state: The active consent state.
        - destinationConfig: The destination's raw config, carrying optional `consentManagement` entries.
        - Returns: `true` when the destination may receive events.
     */
    static func resolve(state: ConsentManagement, destinationConfig: [String: Any]?) -> Bool {
        // Rule 1: disabled -> consented.
        guard state.enabled else { return true }
        
        // Rule 2: no consent data supplied yet -> consented.
        guard state.initialized else { return true }
        
        // Rule 3: first entry matching the active provider; none (or no array) -> consented.
        let entries = destinationConfig?[ConsentResolverConstants.consentManagementKey] as? [[String: Any]] ?? []
        guard let entry = entries.first(where: { ($0[ConsentResolverConstants.providerKey] as? String) == state.provider.value }) else { return true }
        
        // Rule 4: configured consent IDs, trimmed with empties dropped; empty -> consented.
        let configuredIds = ((entry[ConsentResolverConstants.consentsKey] as? [[String: Any]]) ?? [])
            .compactMap { $0[ConsentResolverConstants.consentKey] as? String }
        let cleanedIds = ConsentManagement.normalized(configuredIds)
        guard !cleanedIds.isEmpty else { return true }
        
        // Rules 5 & 6: normalize the strategy, match against the allowed IDs only.
        switch ConsentResolutionStrategy(rawValue: entry[ConsentResolverConstants.resolutionStrategyKey] as? String) {
        case .all:
            return cleanedIds.allSatisfy { state.allowedConsentIds.contains($0) }
        case .any:
            return cleanedIds.contains { state.allowedConsentIds.contains($0) }
        }
    }
}
