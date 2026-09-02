//
//  SetConsentActionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SetConsentAction Tests")
struct SetConsentActionTests {

    @Test("given existing consent lists, when dispatching new options, then both lists are fully replaced")
    func testFullReplacement() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["old-allowed"], deniedConsentIds: ["old-denied"])
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])))

        #expect(state.value.allowedConsentIds == ["marketing"], "The allowed list should be replaced, not merged.")
        #expect(state.value.deniedConsentIds == ["ads"], "The denied list should be replaced, not merged.")
    }

    @Test("given both lists populated, when dispatching options carrying only an allowed list, then the omitted denied list is cleared")
    func testOmittedFieldClears() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["analytics"])))

        #expect(state.value.allowedConsentIds == ["analytics"])
        #expect(state.value.deniedConsentIds.isEmpty, "An omitted list defaults to empty and must clear the previous value — callers always pass the complete state.")
    }

    @Test("given a populated consent state, when dispatching empty options, then the state is unchanged")
    func testEmptyOptionsAreRejected() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions()))

        #expect(state.value == initial, "An update carrying no consent IDs is a contract violation; the reducer must leave the state untouched.")
    }

    @Test("given options carrying only whitespace consent IDs, when dispatched, then the state is unchanged")
    func testWhitespaceOnlyOptionsAreRejected() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["  "], deniedConsentIds: [""])))

        #expect(state.value == initial, "Normalization runs before the emptiness check, so whitespace-only IDs are rejected too.")
    }

    @Test("given a state with no consent data, when dispatching options carrying consent data, then the lists are populated")
    func testUpdateFromEmptyStatePopulatesLists() {
        let initial = ConsentManagement(enabled: true)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(deniedConsentIds: ["ads"])))

        #expect(state.value.deniedConsentIds == ["ads"], "A denied-only update is valid and must be applied.")
        #expect(state.value.allowedConsentIds.isEmpty)
    }

    @Test("given options with messy consent IDs, when dispatched, then the lists are normalized")
    func testRuntimeInputIsNormalized() {
        let state = createState(initialState: ConsentManagement(enabled: true))

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: [" marketing ", ""], deniedConsentIds: ["   ", "ads"])))

        #expect(state.value.allowedConsentIds == ["marketing"], "Runtime input should pass through the same normalizer as load-time input.")
        #expect(state.value.deniedConsentIds == ["ads"])
    }

    @Test("given a disabled state, when dispatching options with consent data, then the state is completely unchanged")
    func testDisabledStateIsNeverModified() {
        let initial = ConsentManagement(enabled: false)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["marketing"])))

        #expect(state.value == initial, "The reducer must be a no-op while disabled — no half-applied state.")
    }

    @Test("given an enabled state, when dispatching any options, then enabled and provider are untouched")
    func testEnabledAndProviderAreNeverModified() {
        let initial = ConsentManagement(enabled: true, provider: .custom)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["marketing"])))

        #expect(state.value.enabled == true, "The action must never modify enabled — it is a load-time decision.")
        #expect(state.value.provider == .custom, "The action must never modify the provider.")
    }
}
