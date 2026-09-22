//
//  ConsentManagementTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("ConsentManagement State Tests")
struct ConsentManagementTests {

    // MARK: - Normalizer

    @Test("given consent IDs with surrounding whitespace, when normalized, then each ID is trimmed")
    func testNormalizerTrimsWhitespace() {
        let normalized = ConsentManagement.normalized([" marketing ", "\tanalytics\n"])

        #expect(normalized == ["marketing", "analytics"], "Every consent ID should be trimmed of whitespace and newlines.")
    }

    @Test("given consent IDs containing empty or whitespace-only entries, when normalized, then those entries are dropped")
    func testNormalizerDropsEmptyEntries() {
        let normalized = ConsentManagement.normalized(["", "   ", "analytics"])

        #expect(normalized == ["analytics"], "Empty and whitespace-only consent IDs should be dropped.")
    }

    // MARK: - Initial State

    @Test("given an enabled configuration with a non-empty list, when the initial state is built, then it is active")
    func testInitialStateEnabledWithDataIsActive() {
        let configuration = ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"])

        let state = ConsentManagement.initialState(configuration)

        #expect(state.active == true, "Enabled with supplied consent data should produce an active state.")
    }

    @Test("given an enabled configuration with both lists empty, when the initial state is built, then it is inactive")
    func testInitialStateEnabledWithoutDataIsInactive() {
        let configuration = ConsentManagementConfiguration(enabled: true)

        let state = ConsentManagement.initialState(configuration)

        #expect(state.active == false, "Enabling consent management without any consent IDs is a configuration error; the state must be built inactive.")
    }

    @Test("given an enabled configuration whose consent IDs are only whitespace, when the initial state is built, then it is inactive")
    func testInitialStateEnabledWithWhitespaceOnlyIdsIsInactive() {
        let configuration = ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["   ", ""], deniedConsentIds: [" "])

        let state = ConsentManagement.initialState(configuration)

        #expect(state.active == false, "IDs that trim to nothing must count as no consent IDs, so the state is built inactive.")
    }

    @Test("given a disabled configuration carrying consent lists, when the initial state is built, then it is inactive")
    func testInitialStateDisabledIsInactive() {
        let configuration = ConsentManagementConfiguration(enabled: false, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])

        let state = ConsentManagement.initialState(configuration)

        #expect(state.active == false, "A disabled configuration can never produce an active state, whatever lists it carries.")
    }

    @Test("given a configuration with messy consent IDs, when the initial state is built, then the lists are normalized")
    func testInitialStateNormalizesLists() {
        let configuration = ConsentManagementConfiguration(
            enabled: true,
            allowedConsentIds: [" marketing ", ""],
            deniedConsentIds: ["  ", "ads"]
        )

        let state = ConsentManagement.initialState(configuration)

        #expect(state.allowedConsentIds == ["marketing"], "Load-time input should pass through the same normalizer as runtime input.")
        #expect(state.deniedConsentIds == ["ads"])
    }

    @Test("given a full configuration, when the initial state is built, then provider and lists are copied over")
    func testInitialStateCopiesAllFields() {
        let configuration = ConsentManagementConfiguration(
            enabled: true,
            provider: .custom,
            allowedConsentIds: ["marketing"],
            deniedConsentIds: ["ads"]
        )

        let state = ConsentManagement.initialState(configuration)

        #expect(state.provider == .custom)
        #expect(state.allowedConsentIds == ["marketing"])
        #expect(state.deniedConsentIds == ["ads"])
    }

    // MARK: - Context Stamp

    @Test("given a state, when stamped and rebuilt, then every gated field round-trips")
    func testContextStampRoundTrips() {
        let original = ConsentManagement(active: true, provider: .custom, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])

        let rebuilt = ConsentManagement.from(contextStamp: original.contextStamp)

        #expect(rebuilt == original, "A stamp must rebuild the state the resolver needs, unchanged.")
    }

    @Test("given a stamp from an unrecognized provider, when rebuilt, then it is nil")
    func testForeignProviderStampIsNotRebuilt() {
        let stamp: [String: Any] = ["provider": "oneTrust", "allowedConsentIds": ["marketing"], "deniedConsentIds": []]

        #expect(ConsentManagement.from(contextStamp: stamp) == nil, "Only the provider the SDK stamps is recognized; anything else must leave the destination ungated.")
    }

    @Test("given a stamp missing its lists, when rebuilt, then both default to empty")
    func testStampWithoutListsRebuildsEmpty() {
        let rebuilt = ConsentManagement.from(contextStamp: ["provider": "custom"])

        #expect(rebuilt?.allowedConsentIds == [], "A malformed stamp must not crash the gate — the lists degrade to empty.")
        #expect(rebuilt?.deniedConsentIds == [])
        #expect(rebuilt?.active == true, "A captured stamp only exists while consent management is active.")
    }

    @Test("given a stamp with messy consent IDs, when rebuilt, then the lists are normalized")
    func testStampNormalizesLists() {
        let stamp: [String: Any] = ["provider": "custom", "allowedConsentIds": [" marketing ", ""], "deniedConsentIds": ["  ", "ads"]]

        let rebuilt = ConsentManagement.from(contextStamp: stamp)

        #expect(rebuilt?.allowedConsentIds == ["marketing"], "A stamp should pass through the same normalizer as every other input.")
        #expect(rebuilt?.deniedConsentIds == ["ads"])
    }
}
