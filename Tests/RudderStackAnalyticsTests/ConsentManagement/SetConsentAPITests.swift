//
//  SetConsentAPITests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SetConsent API Tests")
struct SetConsentAPITests {

    private func makeAnalytics(consent: ConsentManagementConfiguration) -> Analytics {
        let config = MockProvider.createMockConfiguration(storage: MockStorage())
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.consentManagement = consent

        let analytics = Analytics(configuration: config)
        analytics.isAnalyticsActive = true
        return analytics
    }

    // MARK: - setConsent

    @Test("given consent management disabled, when setConsent is called, then the state is unchanged")
    func testSetConsentWhileDisabledIsNoOp() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false))
        let stateBefore = analytics.consentManagementState.value

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))

        #expect(analytics.consentManagementState.value == stateBefore, "setConsent must warn and no-op while consent management is disabled.")
        #expect(analytics.consentManagementState.value.initialized == false)
    }

    @Test("given consent management enabled, when setConsent is called, then the state carries the new lists")
    func testSetConsentWhileEnabledUpdatesState() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]))

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))

        let state = analytics.consentManagementState.value
        #expect(state.allowedConsentIds == ["marketing"])
        #expect(state.deniedConsentIds == ["ads"])
        #expect(state.initialized == true)
    }

    @Test("given consent management enabled with no consent IDs, when analytics is initialized, then the inactive configuration is logged")
    func testEnabledWithoutConsentIdsLogsInactive() {
        let mockLogger = MockLogger()
        let config = MockProvider.createMockConfiguration(storage: MockStorage())
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.consentManagement = ConsentManagementConfiguration(enabled: true)
        config.logger = mockLogger

        let analytics = Analytics(configuration: config)

        #expect(analytics.consentManagementState.value.enabled == false)
        #expect(
            mockLogger.hasLog(level: "INFO", containing: "inactive for this session"),
            "A misconfigured consent setup must tell the developer why the feature is doing nothing."
        )
    }

    @Test("given a consent state set at runtime, when reset is called, then the consent state is identical before and after")
    func testResetLeavesConsentStateUntouched() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]))
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))
        let stateBefore = analytics.consentManagementState.value

        analytics.reset()

        #expect(analytics.consentManagementState.value == stateBefore, "reset() must never touch consent state.")
    }

    // MARK: - Objective-C Parity

    @Test("given every field set through the ObjC builder, when built, then all fields round-trip")
    func testObjCBuilderRoundTripsAllFields() {
        let consent = ObjCConsentConfigurationBuilder()
            .setEnabled(true)
            .setProvider(.custom)
            .setAllowedConsentIds(["marketing", "analytics"])
            .setDeniedConsentIds(["ads"])
            .build()

        #expect(consent.enabled == true)
        #expect(consent.provider == .custom)
        #expect(consent.allowedConsentIds == ["marketing", "analytics"])
        #expect(consent.deniedConsentIds == ["ads"])
    }

    @Test("given no setters called on the ObjC builder, when built, then the disabled defaults apply")
    func testObjCBuilderDefaults() {
        let consent = ObjCConsentConfigurationBuilder().build()

        #expect(consent.enabled == false)
        #expect(consent.provider == .custom)
        #expect(consent.allowedConsentIds.isEmpty)
        #expect(consent.deniedConsentIds.isEmpty)
    }

    @Test("given an ObjC analytics wrapper, when setConsent is called through it, then the wrapped state is updated")
    func testObjCSetConsentDelegates() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]))
        let objcAnalytics = ObjCAnalytics(analytics: analytics)

        objcAnalytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))

        let state = analytics.consentManagementState.value
        #expect(state.allowedConsentIds == ["marketing"], "The ObjC mirror must delegate to the wrapped setConsent.")
        #expect(state.initialized == true)
    }

    @Test("given empty options through the ObjC wrapper, when setConsent is called, then the lists are cleared")
    func testObjCSetConsentWithEmptyOptionsClears() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let objcAnalytics = ObjCAnalytics(analytics: analytics)

        objcAnalytics.setConsent(ConsentManagementOptions())

        let state = analytics.consentManagementState.value
        #expect(state.allowedConsentIds.isEmpty)
        #expect(state.deniedConsentIds.isEmpty)
        #expect(state.initialized == false, "Clearing both lists must revert consent to uninitialized.")
    }
}
