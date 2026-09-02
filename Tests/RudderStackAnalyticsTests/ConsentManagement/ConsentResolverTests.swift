//
//  ConsentResolverTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("ConsentResolver Tests")
struct ConsentResolverTests {

    // MARK: - Rule 1: disabled fails open

    @Test("given consent management disabled, when resolving a gated destination, then it is consented")
    func testDisabledIsConsented() {
        let state = makeState(enabled: false, allowed: [])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing"])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Rule 1: disabled must always resolve consented.")
    }

    // MARK: - Rule 2: entry selection

    @Test("given no consentManagement key, when resolving, then the destination is not gated")
    func testAbsentKeyIsConsented() {
        let state = makeState(allowed: [])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: [:]) == true)
        #expect(ConsentResolver.resolve(state: state, destinationConfig: nil) == true)
    }

    @Test("given an empty consentManagement array, when resolving, then the destination is not gated")
    func testEmptyArrayIsConsented() {
        let state = makeState(allowed: [])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: makeConfig(entries: [])) == true)
    }

    @Test("given only named-provider entries, when resolving with the custom provider, then the destination is not gated")
    func testNoMatchingProviderIsConsented() {
        let state = makeState(allowed: [])
        let config = makeConfig(entries: [
            makeEntry(provider: "oneTrust", consents: ["marketing"]),
            makeEntry(provider: "ketch", consents: ["some-purpose"])
        ])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Rule 2: entries for other providers are never consulted.")
    }

    @Test("given duplicate custom entries, when resolving, then the first match wins")
    func testFirstMatchWinsOnDuplicateProviders() {
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [
            makeEntry(consents: ["not-granted"]),
            makeEntry(consents: ["marketing"])
        ])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == false, "Rule 2: first-match semantics — the second, satisfiable entry must never be consulted.")
    }

    // MARK: - Rule 3: configured consent IDs

    @Test("given an entry with no consents, when resolving, then it is consented")
    func testEmptyConsentsIsConsented() {
        let state = makeState(allowed: [])
        let config = makeConfig(entries: [makeEntry(consents: [])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Rule 3: an empty ID list after cleanup must resolve consented.")
    }

    @Test("given consents that normalize to empty, when resolving, then it is consented")
    func testWhitespaceConsentsAreConsented() {
        let state = makeState(allowed: [])
        let config = makeConfig(entries: [makeEntry(consents: ["   ", ""])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Rule 3: IDs are trimmed and empties dropped before the emptiness check.")
    }

    @Test("given messy configured IDs, when resolving, then they are normalized before matching")
    func testConfiguredIdsAreNormalized() {
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: [" marketing ", "  "])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Configured IDs pass through the same normalizer as state IDs.")
    }

    // MARK: - Rules 4 & 5: strategy matching

    @Test("given the and strategy, when every configured ID is allowed, then it is consented")
    func testAndStrategyAllPresent() {
        let state = makeState(allowed: ["marketing", "analytics"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"], strategy: "and")])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true)
    }

    @Test("given the and strategy, when one configured ID is missing, then it is denied")
    func testAndStrategyOneMissing() {
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"], strategy: "and")])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == false)
    }

    @Test("given the or strategy, when at least one configured ID is allowed, then it is consented")
    func testOrStrategyOnePresent() {
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"], strategy: "or")])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true)
    }

    @Test("given the or strategy, when no configured ID is allowed, then it is denied")
    func testOrStrategyNonePresent() {
        let state = makeState(allowed: ["something-else"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"], strategy: "or")])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == false)
    }

    @Test("given strategy aliases and garbage values, when resolving, then they normalize per the HLD", arguments: [
        ("all", false),
        ("any", true),
        ("or", true),
        ("OR", true),
        (" or ", true),
        ("and", false),
        ("", false),
        ("unknown-strategy", false)
    ])
    func testStrategyNormalization(_ strategy: String, _ expected: Bool) {
        // One of two configured IDs is allowed: or-matching consents, and-matching denies.
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"], strategy: strategy)])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == expected, "Rule 4: 'or'/'any' select or-matching (trimmed, case-insensitive); everything else selects and-matching.")
    }

    @Test("given no resolutionStrategy field, when resolving, then and-matching applies")
    func testMissingStrategyDefaultsToAnd() {
        let state = makeState(allowed: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing", "analytics"])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == false, "Rule 4: a missing strategy selects and-matching.")
    }

    // MARK: - Denied list is never consulted

    @Test("given a configured ID present in both lists, when resolving, then the denied list is ignored")
    func testDeniedListNeverConsulted() {
        let state = makeState(allowed: ["marketing"], denied: ["marketing"])
        let config = makeConfig(entries: [makeEntry(consents: ["marketing"])])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Only allowedConsentIds participate in matching — deniedConsentIds are stamp-only.")
    }

    // MARK: - Rule 6: malformed shapes fail open

    @Test("given malformed consentManagement shapes, when resolving, then every one fails open", arguments: [
        ["consentManagement": "not-an-array"] as [String: Any],
        ["consentManagement": [42, "string"]] as [String: Any],
        ["consentManagement": [["provider": 42]]] as [String: Any],
        ["consentManagement": [["provider": "custom", "consents": "not-an-array"]]] as [String: Any],
        ["consentManagement": [["provider": "custom", "consents": [["consent": 42]]]]] as [String: Any]
    ])
    func testMalformedShapesFailOpen(_ config: [String: Any]) {
        let state = makeState(allowed: [])

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Rule 6: malformed configuration must resolve consented, never break delivery.")
    }

    @Test("given legacy provider fields beside the generic array, when resolving, then they are ignored")
    func testLegacyFieldsAreIgnored() {
        let state = makeState(allowed: ["marketing"])
        var config = makeConfig(entries: [makeEntry(consents: ["marketing"])])
        config["ketchConsentPurposes"] = [["purpose": "analytics"]]

        #expect(ConsentResolver.resolve(state: state, destinationConfig: config) == true, "Legacy provider-specific fields must not affect the verdict.")
    }
}

// MARK: - Helpers
extension ConsentResolverTests {
    
    private func makeState(enabled: Bool = true, allowed: [String] = [], denied: [String] = []) -> ConsentManagement {
        ConsentManagement(enabled: enabled, provider: .custom, allowedConsentIds: allowed, deniedConsentIds: denied)
    }

    private func makeConfig(entries: [[String: Any]]) -> [String: Any] {
        [ConsentResolverConstants.consentManagementKey: entries]
    }

    private func makeEntry(provider: String = "custom", consents: [String], strategy: String? = nil) -> [String: Any] {
        var entry: [String: Any] = [
            ConsentResolverConstants.providerKey: provider,
            ConsentResolverConstants.consentsKey: consents.map { [ConsentResolverConstants.consentKey: $0] }
        ]
        if let strategy {
            entry[ConsentResolverConstants.resolutionStrategyKey] = strategy
        }
        return entry
    }
}
