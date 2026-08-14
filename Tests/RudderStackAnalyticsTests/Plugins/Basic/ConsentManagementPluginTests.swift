//
//  ConsentManagementPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 14/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("ConsentManagementPlugin Tests")
struct ConsentManagementPluginTests {

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

    private func makePlugin(for analytics: Analytics) -> ConsentManagementPlugin {
        let plugin = ConsentManagementPlugin()
        plugin.setup(analytics: analytics)
        return plugin
    }

    private func makeTrackEvent(options: RudderOption? = nil) -> Event {
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, options: options)
        event = event.updateEventData()
        MockProvider.resetDynamicValues(&event)
        return event
    }

    private var legacyOption: RudderOption {
        RudderOption(customContext: ["consentManagement": ["provider": "legacy", "allowedConsentIds": ["legacy-id"]]])
    }

    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let plugin = makePlugin(for: makeAnalytics(consent: ConsentManagementConfiguration(enabled: true)))

        #expect(plugin.analytics != nil)
        #expect(plugin.pluginType == .preProcess)
    }

    @Test("given consent management enabled, when an event is intercepted, then the payload matches the golden fixture")
    func testEnabledStampsExactBlock() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"], deniedConsentIds: ["advertising"]))
        let plugin = makePlugin(for: analytics)

        guard let stamped = plugin.intercept(event: makeTrackEvent()) else {
            Issue.record("The plugin must never drop an event.")
            return
        }

        guard let json = stamped.jsonString?.trimmed, let expected = MockProvider.readJson(from: "track_with_consent_management")?.trimmed else {
            Issue.record("Failed to serialize the event or read the golden fixture.")
            return
        }
        #expect(json == expected)
    }

    @Test("given consent management disabled, when an event is intercepted, then the consentManagement key is absent")
    func testDisabledLeavesKeyAbsent() {
        let plugin = makePlugin(for: makeAnalytics(consent: ConsentManagementConfiguration(enabled: false)))
        let event = makeTrackEvent()

        let result = plugin.intercept(event: event)

        #expect(result?.context?["consentManagement"] == nil, "Disabled must mean no block at all — not an empty one.")
        #expect(result?.jsonString == event.jsonString, "A disabled plugin must pass the event through untouched.")
    }

    @Test("given a legacy injected key while enabled, when an event is intercepted, then the SDK block wins and a warning is logged")
    func testOverrideWinsWithWarningOnLegacyInjection() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let plugin = makePlugin(for: analytics)

        let result = plugin.intercept(event: makeTrackEvent(options: legacyOption))

        guard let context = result?.context?.rawDictionary, let block = context["consentManagement"] as? [String: Any] else {
            Issue.record("The consentManagement block was not stamped.")
            return
        }
        #expect(block["provider"] as? String == "custom", "The SDK block must replace the injected value entirely.")
        #expect(block["allowedConsentIds"] as? [String] == ["marketing"])
        #expect(block["deniedConsentIds"] as? [String] == [])

        let warnings = mockLogger.logs.filter { $0.level == "WARN" }
        #expect(warnings.count == 1, "Exactly one migration warning must be logged.")
        #expect(warnings.first?.message.contains("consentManagement") == true, "The warning must name the key.")
        #expect(warnings.first?.message.contains("legacy-id") == false, "The warning must stay value-free.")
    }

    @Test("given a legacy injected key while disabled, when an event is intercepted, then the key is preserved with no warning")
    func testDisabledPreservesLegacyKeySilently() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let plugin = makePlugin(for: analytics)

        let result = plugin.intercept(event: makeTrackEvent(options: legacyOption))

        guard let context = result?.context?.rawDictionary, let block = context["consentManagement"] as? [String: Any] else {
            Issue.record("The legacy injected block must survive while disabled.")
            return
        }
        #expect(block["provider"] as? String == "legacy", "The legacy customContext injection path must keep working while disabled.")
        #expect(mockLogger.logs.allSatisfy { $0.level != "WARN" }, "No warning while disabled — the SDK is not claiming the key.")
    }

    @Test("given the state is updated between events, when a second event is intercepted, then it carries the new lists")
    func testStateUpdateReflectsOnNextEvent() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makePlugin(for: analytics)

        let first = plugin.intercept(event: makeTrackEvent())
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["analytics"], deniedConsentIds: ["advertising"]))
        let second = plugin.intercept(event: makeTrackEvent())

        let firstBlock = first?.context?.rawDictionary["consentManagement"] as? [String: Any]
        let secondBlock = second?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(firstBlock?["allowedConsentIds"] as? [String] == ["marketing"])
        #expect(secondBlock?["allowedConsentIds"] as? [String] == ["analytics"], "The stamp must reflect the state at event creation.")
        #expect(secondBlock?["deniedConsentIds"] as? [String] == ["advertising"])
    }
}
