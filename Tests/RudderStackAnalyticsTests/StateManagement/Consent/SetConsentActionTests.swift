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
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["old-allowed"], deniedConsentIds: ["old-denied"], initialized: true)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"])))

        #expect(state.value.allowedConsentIds == ["marketing"], "The allowed list should be replaced, not merged.")
        #expect(state.value.deniedConsentIds == ["ads"], "The denied list should be replaced, not merged.")
    }

    @Test("given both lists populated, when dispatching options carrying only an allowed list, then the omitted denied list is cleared")
    func testOmittedFieldClears() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"], initialized: true)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["analytics"])))

        #expect(state.value.allowedConsentIds == ["analytics"])
        #expect(state.value.deniedConsentIds.isEmpty, "An omitted list defaults to empty and must clear the previous value — callers always pass the complete state.")
    }

    @Test("given a populated consent state, when dispatching empty options, then the state reverts to uninitialized")
    func testEmptyOptionsClearAndRevertToUninitialized() {
        let initial = ConsentManagement(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"], initialized: true)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions()))

        #expect(state.value.allowedConsentIds.isEmpty)
        #expect(state.value.deniedConsentIds.isEmpty)
        #expect(state.value.initialized == false, "An empty update must revert to the fail-open uninitialized state (JS parity).")
    }

    @Test("given an uninitialized state, when dispatching options with consent data, then the state becomes initialized")
    func testUpdateWithDataInitializes() {
        let initial = ConsentManagement(enabled: true, initialized: false)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(deniedConsentIds: ["ads"])))

        #expect(state.value.initialized == true, "Supplying consent data through an update should initialize the state.")
    }

    @Test("given options with messy consent IDs, when dispatched, then the lists are normalized")
    func testRuntimeInputIsNormalized() {
        let state = createState(initialState: ConsentManagement(enabled: true))

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: [" marketing ", ""], deniedConsentIds: ["   ", "ads"])))

        #expect(state.value.allowedConsentIds == ["marketing"], "Runtime input should pass through the same normalizer as load-time input.")
        #expect(state.value.deniedConsentIds == ["ads"])
    }

    @Test("given an enabled state, when dispatching any options, then enabled and provider are untouched")
    func testEnabledAndProviderAreNeverModified() {
        let initial = ConsentManagement(enabled: true, provider: .custom, initialized: false)
        let state = createState(initialState: initial)

        state.dispatch(action: SetConsentAction(options: ConsentManagementOptions(allowedConsentIds: ["marketing"])))

        #expect(state.value.enabled == true, "The action must never modify enabled — it is a load-time decision.")
        #expect(state.value.provider == .custom, "The action must never modify the provider.")
    }
}
