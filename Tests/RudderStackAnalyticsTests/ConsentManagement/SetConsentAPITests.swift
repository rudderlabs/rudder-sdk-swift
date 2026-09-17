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

    private func makeAnalytics(consent: ConsentManagementConfiguration, logger: Logger? = nil) -> Analytics {
        let config = MockProvider.createMockConfiguration(storage: MockStorage())
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        config.consentManagement = consent
        if let logger { config.logger = logger }

        let analytics = Analytics(configuration: config)
        analytics.isAnalyticsActive = true
        return analytics
    }

    // MARK: - setConsent

    @Test("given consent management disabled, when setConsent is called, then it warns that consent management is not active and the state is unchanged")
    func testSetConsentWhileDisabledIsNoOp() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let stateBefore = analytics.consentManagementState.value

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))

        #expect(analytics.consentManagementState.value == stateBefore, "setConsent must warn and no-op while consent management is disabled.")
        #expect(mockLogger.hasLog(level: "WARN", containing: "Consent management is not active"))
    }

    // Enabled with no consent IDs leaves consent management inactive for the session. The warning must
    // point at the missing IDs, not tell a developer who already enabled the feature to enable it.
    @Test("given consent management enabled without consent IDs, when setConsent is called, then it warns that at least one consent ID is needed")
    func testSetConsentWhileInactiveNamesTheMissingIds() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true), logger: mockLogger)
        let stateBefore = analytics.consentManagementState.value

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))

        #expect(analytics.consentManagementState.value == stateBefore, "setConsent must no-op while consent management is inactive.")
        #expect(mockLogger.hasLog(level: "WARN", containing: "Consent management is not active"))
        #expect(mockLogger.hasLog(level: "WARN", containing: "provide at least one consent ID"))
    }

    @Test("given consent management enabled, when setConsent is called, then the state carries the new lists")
    func testSetConsentWhileEnabledUpdatesState() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]))

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"], deniedConsentIds: ["ads"]))

        let state = analytics.consentManagementState.value
        #expect(state.allowedConsentIds == ["marketing"])
        #expect(state.deniedConsentIds == ["ads"])
    }

    @Test("given consent management enabled with no consent IDs, when analytics is initialized, then the inactive configuration is logged")
    func testEnabledWithoutConsentIdsLogsInactive() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true), logger: mockLogger)

        #expect(analytics.consentManagementState.value.active == false)
        #expect(
            mockLogger.hasLog(level: "INFO", containing: "inactive for this session"),
            "A misconfigured consent setup must tell the developer why the feature is doing nothing."
        )
    }

    @Test("given consent management enabled, when setConsent is called with no consent IDs, then the call is refused with a warning")
    func testSetConsentWithoutConsentIdsIsRefused() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]), logger: mockLogger)
        let stateBefore = analytics.consentManagementState.value

        analytics.setConsent(ConsentManagementOptions())

        #expect(analytics.consentManagementState.value == stateBefore, "A setConsent call carrying no consent IDs must leave the state untouched.")
        #expect(mockLogger.hasLog(level: "WARN", containing: "requires at least one consent ID"))
    }

    @Test("given consent management enabled, when setConsent is called with IDs that are only whitespace, then the call is refused with a warning")
    func testSetConsentWithWhitespaceOnlyIdsIsRefused() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]), logger: mockLogger)
        let stateBefore = analytics.consentManagementState.value

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["  ", ""], deniedConsentIds: [" "]))

        #expect(analytics.consentManagementState.value == stateBefore, "IDs that trim to nothing must count as no consent IDs.")
        #expect(mockLogger.hasLog(level: "WARN", containing: "requires at least one consent ID"))
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
        let consent = ObjCConsentManagementConfigurationBuilder()
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
        let consent = ObjCConsentManagementConfigurationBuilder().build()

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
    }

    @Test("given empty options through the ObjC wrapper, when setConsent is called, then the call is refused")
    func testObjCSetConsentWithEmptyOptionsIsRefused() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let objcAnalytics = ObjCAnalytics(analytics: analytics)

        objcAnalytics.setConsent(ConsentManagementOptions())

        let state = analytics.consentManagementState.value
        #expect(state.allowedConsentIds == ["marketing"], "The ObjC mirror must inherit the refusal, not clear the lists.")
    }
}
