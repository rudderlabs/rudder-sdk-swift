//
//  ContextGuardPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 19/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("ContextGuardPlugin Tests")
struct ContextGuardPluginTests {

    static let sentinel = "sentinel-value-123"

    // MARK: - Setup

    @Test("when setup is called, then the plugin runs in the terminal phase")
    func testPluginSetup() {
        let (_, guardPlugin) = makeGuard(for: makeAnalytics(consent: ConsentManagementConfiguration(enabled: true)))

        #expect(guardPlugin.analytics != nil)
        #expect(guardPlugin.pluginType == .terminal)
    }

    // MARK: - Consent Stamp Enforcement

    @Test("given a plugin-written consent block while enabled, when the guard runs, then the block is restored with a warning")
    func testPluginWrittenConsentIsReplaced() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let stamper = makeStamper(for: analytics)

        var event = makeTrackEvent()
        event = stamper.intercept(event: event) ?? event
        event = snapshot.intercept(event: event) ?? event
        // A customer plugin spoofing the stamp after the SDK wrote it.
        event = event.addToContext(info: ["consentManagement": ["provider": Self.sentinel]])

        let result = guardPlugin.intercept(event: event)

        let block = result?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "The guard must restore the SDK block.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])

        let warnings = warnMessages(in: mockLogger)
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("consentManagement") == true, "The warning must name the key.")
        #expect(warnings.first?.contains(Self.sentinel) == false, "The warning must stay value-free.")
    }

    @Test("given the stamp is missing while enabled, when the guard runs, then the block is restored with a warning")
    func testMissingStampIsRestored() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        // Never stamped — equivalent to a customer plugin deleting the key.
        var event = makeTrackEvent()
        event = snapshot.intercept(event: event) ?? event

        let result = guardPlugin.intercept(event: event)

        let block = result?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom")
        #expect(warnMessages(in: mockLogger).count == 1)
    }

    @Test("given a legacy customContext injection while enabled, when the stamper already replaced it, then the guard stays silent")
    func testNoDoubleWarningAfterStamperReplacement() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let stamper = makeStamper(for: analytics)

        var event = makeTrackEvent(options: RudderOption(customContext: ["consentManagement": ["provider": "legacy"]]))
        event = stamper.intercept(event: event) ?? event
        event = snapshot.intercept(event: event) ?? event
        let before = event.jsonString

        let result = guardPlugin.intercept(event: event)

        #expect(result?.jsonString == before, "An already-correct stamp must pass through untouched.")
        #expect(warnMessages(in: mockLogger).count == 1, "Only the stamper's migration warning — the guard must not double-warn.")
    }

    @Test("given consent management disabled, when the guard runs, then a customer consent block passes through with no warning")
    func testDisabledPassesCustomerBlockThrough() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent(options: RudderOption(customContext: ["consentManagement": ["provider": "legacy"]]))
        event = snapshot.intercept(event: event) ?? event
        let before = event.jsonString

        let result = guardPlugin.intercept(event: event)

        let block = result?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "legacy", "Disabled means the key is not reserved.")
        #expect(result?.jsonString == before)
        #expect(warnMessages(in: mockLogger).isEmpty)
    }

    @Test("given no collisions, when the guard runs, then the payload is identical with no warnings")
    func testNoCollisionParity() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let stamper = makeStamper(for: analytics)

        var event = makeTrackEvent()
        event = stamper.intercept(event: event) ?? event
        event = snapshot.intercept(event: event) ?? event
        let before = event.jsonString

        let result = guardPlugin.intercept(event: event)

        #expect(result?.jsonString == before, "A clean event must pass through byte-identical.")
        #expect(warnMessages(in: mockLogger).isEmpty)
    }

    // MARK: - Base Key Detection

    @Test("given a base key injected via customContext, when the guard runs, then a value-free deprecation warning names the key", arguments: SDKManagedContextKey.baseKeys)
    func testBaseKeyCustomContextWarns(key: SDKManagedContextKey) {
        let mockLogger = MockLogger()
        // Consent disabled on purpose: base-key detection is independent of consent state.
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent(options: RudderOption(customContext: [key.rawValue: Self.sentinel]))
        event = snapshot.intercept(event: event) ?? event
        let before = event.jsonString

        let result = guardPlugin.intercept(event: event)

        #expect(result?.jsonString == before, "Detection must never modify the event.")
        let warnings = warnMessages(in: mockLogger)
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("\"\(key.rawValue)\"") == true)
        #expect(warnings.first?.contains(Self.sentinel) == false, "The warning must stay value-free.")
    }

    @Test("given a base key written by a customer plugin, when the guard runs, then the value is delivered with a deprecation warning", arguments: SDKManagedContextKey.baseKeys)
    func testBaseKeyPluginWriteWarns(key: SDKManagedContextKey) {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent()
        event = snapshot.intercept(event: event) ?? event
        // A customer plugin writing the key after the SDK stampers ran.
        event = event.addToContext(info: [key.rawValue: Self.sentinel])

        let result = guardPlugin.intercept(event: event)

        #expect(result?.context?.rawDictionary[key.rawValue] as? String == Self.sentinel, "Detection only — the customer value must still be delivered.")
        let warnings = warnMessages(in: mockLogger)
        #expect(warnings.count == 1)
        #expect(warnings.first?.contains("\"\(key.rawValue)\"") == true)
        #expect(warnings.first?.contains(Self.sentinel) == false)
    }

    @Test("given a base key overridden via customContext plus a plugin, when the guard runs, then the key warns exactly once")
    func testOverriddenKeyWarnsOnce() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent(options: RudderOption(customContext: ["library": Self.sentinel]))
        event = snapshot.intercept(event: event) ?? event
        event = event.addToContext(info: ["library": "another-value"])

        _ = guardPlugin.intercept(event: event)

        #expect(warnMessages(in: mockLogger).count == 1, "Both detection paths hitting the same key must union into one warning.")
    }

    @Test("given non-reserved custom keys, when the guard runs, then they pass through with no warning")
    func testNonReservedKeysUntouched() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent(options: RudderOption(customContext: ["campaign": Self.sentinel]))
        event = snapshot.intercept(event: event) ?? event
        event = event.addToContext(info: ["pluginKey": "plugin-value"])

        let result = guardPlugin.intercept(event: event)

        #expect(result?.context?.rawDictionary["campaign"] as? String == Self.sentinel)
        #expect(result?.context?.rawDictionary["pluginKey"] as? String == "plugin-value")
        #expect(warnMessages(in: mockLogger).isEmpty, "Non-stamped keys are the customer's — never warn.")
    }

    @Test("given a plugin that rewraps the whole context, when values are unchanged, then no deprecation warning fires")
    func testContextRewrapDoesNotWarn() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        var event = makeTrackEvent()
        event = event.addToContext(info: ["network": ["wifi": true, "cellular": false], "screen": ["density": 3], "sessionId": 1787206641])
        event = snapshot.intercept(event: event) ?? event
        // A customer plugin rebuilding the context via rawDictionary changes number
        // representations without changing values — the ATT sample plugin pattern.
        event.context = (event.context?.rawDictionary ?? [:]).codableWrapped

        _ = guardPlugin.intercept(event: event)

        #expect(warnMessages(in: mockLogger).isEmpty, "Representation changes are not overrides.")
    }

    @Test("given a stale snapshot from another event, when the guard runs, then no plugin-path warning fires")
    func testStaleSnapshotStaysSilent() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)

        _ = snapshot.intercept(event: makeTrackEvent())          // The slot holds another event's snapshot.
        var event = makeTrackEvent()
        event = event.addToContext(info: ["library": Self.sentinel])

        let result = guardPlugin.intercept(event: event)

        #expect(result?.context?.rawDictionary["library"] as? String == Self.sentinel)
        #expect(warnMessages(in: mockLogger).isEmpty, "A mismatched snapshot must fail safe — silence, never a false warning.")
    }
}

// MARK: - Helpers
extension ContextGuardPluginTests {

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

    private func makeGuard(for analytics: Analytics) -> (snapshot: ContextSnapshotPlugin, guardPlugin: ContextGuardPlugin) {
        let snapshot = ContextSnapshotPlugin()
        snapshot.setup(analytics: analytics)
        let guardPlugin = ContextGuardPlugin(snapshotPlugin: snapshot)
        guardPlugin.setup(analytics: analytics)
        return (snapshot, guardPlugin)
    }

    private func makeStamper(for analytics: Analytics) -> ConsentManagementPlugin {
        let plugin = ConsentManagementPlugin()
        plugin.setup(analytics: analytics)
        return plugin
    }

    private func makeTrackEvent(options: RudderOption? = nil) -> Event {
        let event: Event = TrackEvent(event: MockProvider.SampleEventName.track, options: options)
        return event.updateEventData()
    }

    private func warnMessages(in logger: MockLogger) -> [String] {
        logger.logs.filter { $0.level == "WARN" }.map { $0.message }
    }
}
