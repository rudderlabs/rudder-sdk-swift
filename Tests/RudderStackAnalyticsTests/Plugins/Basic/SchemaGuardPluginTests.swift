//
//  SchemaGuardPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 19/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("SchemaGuardPlugin Tests")
struct SchemaGuardPluginTests {

    static let sentinel = "sentinel-value-123"

    // MARK: - Setup

    @Test("when setup is called, then the plugin runs in the terminal phase")
    func testPluginSetup() {
        let (_, guardPlugin) = makeGuard(for: makeAnalytics(consent: ConsentManagementConfiguration(enabled: true)))

        #expect(guardPlugin.analytics != nil)
        #expect(guardPlugin.pluginType == .terminal)
    }

    // MARK: - Managed Key Sets

    @Test("given the managed key sets, then reserved and base keys partition every case")
    func testManagedKeyPartition() {
        #expect(SDKManagedContextKey.reservedKeys.contains(.consentManagement))
        #expect(!SDKManagedContextKey.baseKeys.contains(.consentManagement))
        #expect(
            Set(SDKManagedContextKey.baseKeys).union(SDKManagedContextKey.reservedKeys)
                == Set(SDKManagedContextKey.allCases)
        )
    }

    // MARK: - Consent Stamp Enforcement

    @Test("given a plugin-written consent block while enabled, when the guard runs, then the block is restored with a warning")
    func testPluginWrittenConsentIsReplaced() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let stamper = makeStamper(for: analytics)

        var event = makeTrackEvent(for: analytics)
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
        var event = makeTrackEvent(for: analytics)
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

        var event = makeTrackEvent(options: RudderOption(customContext: ["consentManagement": ["provider": "legacy"]]), for: analytics)
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

        var event = makeTrackEvent(for: analytics)
        event = stamper.intercept(event: event) ?? event
        event = snapshot.intercept(event: event) ?? event
        let before = event.jsonString

        let result = guardPlugin.intercept(event: event)

        #expect(result?.jsonString == before, "A clean event must pass through byte-identical.")
        #expect(warnMessages(in: mockLogger).isEmpty)
    }

    @Test("given consent changed after the event was created, when the guard runs, then the event keeps the consent captured at creation")
    func testGuardRestoresConsentCapturedAtCreation() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let stamper = makeStamper(for: analytics)

        var event = makeTrackEvent(for: analytics)
        event = stamper.intercept(event: event) ?? event
        event = snapshot.intercept(event: event) ?? event

        // The user widens consent while the event is still in flight.
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing", "analytics"]))

        let result = guardPlugin.intercept(event: event)

        let block = result?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(
            block?["allowedConsentIds"] as? [String] == ["marketing"],
            "A decision taken after the event was created must not rewrite what the event recorded."
        )
    }

    // Driven through a real chain: the event's own bookkeeping has to be put back where the chain takes
    // the plugin's result, or the guard has nothing to restore from.
    @Test("given a plugin that rebuilds the event with a spoofed consent block, when the chain runs, then the SDK block reaches the terminal consumers")
    func testRebuiltEventStillReachesTerminalWithTheSdkConsentBlock() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let capture = MockEventCapturePlugin()
        let chain = PluginChain(analytics: analytics)
        chain.add(plugin: makeStamper(for: analytics))
        chain.add(plugin: snapshot)
        chain.add(plugin: ConsentSpoofingRebuildPlugin())
        chain.add(plugin: guardPlugin)
        chain.add(plugin: capture)

        chain.process(event: makeTrackEvent(for: analytics))

        let block = capture.capturedEvents.first?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "A rebuilt event must not smuggle a spoofed consent block past the guard.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])
    }

    // A customer-defined event type has nowhere to hold the consent recorded at creation, so passing
    // through one must not lose it: a grant spoofed on the way must not survive to the terminal consumers.
    @Test("given plugins that pass the event through a customer-defined event type in one phase, when the chain runs, then the consent recorded at creation reaches the terminal consumers")
    func testCustomerEventTypeInOnePhaseKeepsRecordedConsent() {
        let block = runChainThroughCustomerEventType(swapPhase: .onProcess)

        #expect(block?["allowedConsentIds"] as? [String] == ["analytics"])
        #expect(block?["deniedConsentIds"] as? [String] == ["marketing"], "A grant spoofed through a customer event type must not survive.")
    }

    @Test("given plugins that pass the event through a customer-defined event type across phases, when the chain runs, then the consent recorded at creation reaches the terminal consumers")
    func testCustomerEventTypeAcrossPhasesKeepsRecordedConsent() {
        let block = runChainThroughCustomerEventType(swapPhase: .preProcess)

        #expect(block?["allowedConsentIds"] as? [String] == ["analytics"])
        #expect(block?["deniedConsentIds"] as? [String] == ["marketing"], "A grant spoofed through a customer event type must not survive.")
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
extension SchemaGuardPluginTests {

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

    private func makeGuard(for analytics: Analytics) -> (snapshot: ContextSnapshotPlugin, guardPlugin: SchemaGuardPlugin) {
        let snapshot = ContextSnapshotPlugin()
        snapshot.setup(analytics: analytics)
        let guardPlugin = SchemaGuardPlugin(snapshotPlugin: snapshot)
        guardPlugin.setup(analytics: analytics)
        return (snapshot, guardPlugin)
    }

    private func makeStamper(for analytics: Analytics) -> ConsentManagementPlugin {
        let plugin = ConsentManagementPlugin()
        plugin.setup(analytics: analytics)
        return plugin
    }

    /// Mirrors what `Analytics.process` does at creation: passing `analytics` records the reserved
    /// values in force at that moment, which is what the guard restores from.
    private func makeTrackEvent(options: RudderOption? = nil, for analytics: Analytics? = nil) -> Event {
        var event: Event = TrackEvent(event: MockProvider.SampleEventName.track, options: options)
        if let analytics, var carrier = event as? ReservedContextCapturing {
            carrier.capturedReservedContext = analytics.capturedReservedContext()
            event = carrier
        }
        return event.updateEventData()
    }

    /// Runs a real chain in which one customer plugin swaps the event for a customer-defined type carrying a
    /// spoofed grant, and another converts it back to a `TrackEvent`. Returns the consent block the terminal
    /// consumers receive.
    private func runChainThroughCustomerEventType(swapPhase: PluginType) -> [String: Any]? {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"], deniedConsentIds: ["marketing"]))
        let (snapshot, guardPlugin) = makeGuard(for: analytics)
        let capture = MockEventCapturePlugin()
        let spoofedGrant: [String: Any] = ["consentManagement": ["provider": "custom", "allowedConsentIds": ["marketing"], "deniedConsentIds": [String]()]]
        let chain = PluginChain(analytics: analytics)
        chain.add(plugin: makeStamper(for: analytics))
        chain.add(plugin: snapshot)
        chain.add(plugin: MockCustomerEventSwappingPlugin(pluginType: swapPhase, contextInfo: spoofedGrant))
        chain.add(plugin: MockCustomerEventConvertingPlugin())
        chain.add(plugin: guardPlugin)
        chain.add(plugin: capture)

        chain.process(event: makeTrackEvent(for: analytics))

        return capture.capturedEvents.first?.context?.rawDictionary["consentManagement"] as? [String: Any]
    }

    private func warnMessages(in logger: MockLogger) -> [String] {
        logger.logs.filter { $0.level == "WARN" }.map { $0.message }
    }
}

// MARK: - ConsentSpoofingRebuildPlugin
/// A customer plugin that returns a newly built event instead of the one it was handed, copying what it
/// can see and spoofing the consent block.
private final class ConsentSpoofingRebuildPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?

    func intercept(event: any Event) -> (any Event)? {
        guard let track = event as? TrackEvent else { return event }
        var rebuilt = TrackEvent(event: track.event)
        rebuilt.anonymousId = track.anonymousId
        rebuilt.userId = track.userId
        rebuilt.integrations = track.integrations
        rebuilt.context = track.context
        return rebuilt.addToContext(info: ["consentManagement": ["provider": SchemaGuardPluginTests.sentinel]])
    }
}
