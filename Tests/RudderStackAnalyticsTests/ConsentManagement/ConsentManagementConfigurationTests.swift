//
//  ConsentManagementConfigurationTests.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 13/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("ConsentManagementConfiguration Tests")
struct ConsentManagementConfigurationTests {

    @Test("given no consent configuration, when a Configuration is created, then consent management is disabled with defaults")
    func testConfigurationWithoutConsentDefaultsToDisabled() {
        let config = Configuration(writeKey: MockConstant.mockWriteKey, dataPlaneUrl: MockConstant.mockDataPlaneUrl)

        #expect(config.consentManagement.enabled == false, "Consent management should be disabled by default.")
        #expect(config.consentManagement.provider == .custom, "The default provider should be custom.")
        #expect(config.consentManagement.allowedConsentIds.isEmpty, "Allowed consent IDs should default to empty.")
        #expect(config.consentManagement.deniedConsentIds.isEmpty, "Denied consent IDs should default to empty.")
    }

    @Test("given a full consent configuration, when a Configuration is created, then every field round-trips")
    func testConfigurationRoundTripsAllFields() {
        let consent = ConsentManagementConfiguration(
            enabled: true,
            provider: .custom,
            allowedConsentIds: ["marketing", "analytics"],
            deniedConsentIds: ["advertising"]
        )
        let config = Configuration(writeKey: MockConstant.mockWriteKey, dataPlaneUrl: MockConstant.mockDataPlaneUrl, consentManagement: consent)

        #expect(config.consentManagement.enabled == true)
        #expect(config.consentManagement.provider == .custom)
        #expect(config.consentManagement.allowedConsentIds == ["marketing", "analytics"])
        #expect(config.consentManagement.deniedConsentIds == ["advertising"])
    }

    @Test("given no arguments, when a ConsentManagementConfiguration is created, then defaults are applied")
    func testConsentConfigurationDefaults() {
        let consent = ConsentManagementConfiguration()

        #expect(consent.enabled == false, "enabled should default to the disabled state.")
        #expect(consent.provider == .custom)
        #expect(consent.allowedConsentIds.isEmpty)
        #expect(consent.deniedConsentIds.isEmpty)
    }

    @Test("given the default config constants, when consent management default is read, then it is disabled")
    func testDefaultConfigWiring() {
        #expect(Constants.defaultConfig.consentManagementEnabled == false, "Constants.defaultConfig must carry the disabled default.")
    }

    @Test("given the custom provider, when its wire value is read, then it serializes as custom")
    func testProviderWireValue() {
        #expect(ConsentManagementProvider.custom.value == "custom", "The provider must serialize to the exact wire string the server expects.")
    }
}
