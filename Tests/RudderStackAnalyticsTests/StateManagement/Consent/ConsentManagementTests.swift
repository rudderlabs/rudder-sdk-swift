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

        #expect(state.enabled == true, "Enabled with supplied consent data should produce an active state.")
    }

    @Test("given an enabled configuration with both lists empty, when the initial state is built, then it is inactive")
    func testInitialStateEnabledWithoutDataIsInactive() {
        let configuration = ConsentManagementConfiguration(enabled: true)

        let state = ConsentManagement.initialState(configuration)

        #expect(state.enabled == false, "Enabling consent management without any consent IDs is a configuration error; the state must be built inactive.")
    }

    @Test("given a disabled configuration carrying consent lists, when the initial state is built, then it is inactive")
    func testInitialStateDisabledIsInactive() {
        let configuration = ConsentManagementConfiguration(enabled: false, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])

        let state = ConsentManagement.initialState(configuration)

        #expect(state.enabled == false, "A disabled configuration can never produce an active state, whatever lists it carries.")
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
}
