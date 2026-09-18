//
//  DeviceModeConsentRestampTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 19/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("Device-Mode Consent Restamp Tests")
struct DeviceModeConsentRestampTests {

    private let destinationKey = "MockDestination"
    static let sentinel = "sentinel-value-123"

    @Test("given a customContext consent block, when the event is delivered to a destination, then the SDK block is delivered")
    func testInjectedBlockIsReplacedOnDelivery() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        let options = RudderOption(customContext: ["consentManagement": ["provider": Self.sentinel]])
        _ = plugin.intercept(event: makeTrackEvent(named: "with-injection", options: options, for: analytics))

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "The delivered payload must carry the SDK block.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])
    }

    @Test("given a destination-chain plugin spoofing the stamp, when the event is delivered, then the SDK block is restored")
    func testDestinationChainSpoofIsReplacedOnDelivery() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)
        plugin.add(plugin: ContextMutatingPlugin(info: ["consentManagement": ["provider": Self.sentinel]]))

        _ = plugin.intercept(event: makeTrackEvent(named: "spoofed", for: analytics))

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "The restamp must run after the destination's own plugin chain.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])
    }

    @Test("given buffered events replayed after a grant, when delivered, then each carries the consent recorded at creation")
    func testReplayedEventsCarryCurrentStamp() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.createCalled == false, "Precondition: the destination starts denied.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        plugin.onCreate = { [weak analytics, weak plugin] in
            guard let plugin else { return }
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-init", for: analytics), to: plugin)
        }
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.receivedTrackEventNames == ["during-init"], "Precondition: the buffered event must replay.")
        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"], "A replayed event must carry the consent it was created under.")
    }

    @Test("given consent management disabled, when a customer block rides the event, then it is delivered untouched")
    func testDisabledDeliversCustomerBlockUntouched() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        let options = RudderOption(customContext: ["consentManagement": ["provider": "legacy"]])
        _ = plugin.intercept(event: makeTrackEvent(named: "legacy-event", options: options))

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "legacy", "Disabled means the key is not reserved — the customer value must be delivered.")
    }

    @Test("given a consent flip without reinitialization, when the event gate drops the event, then the restamp is bypassed harmlessly")
    func testDroppedEventBypassesRestamp() async throws {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        // The event gate caches its destination config from the source-config state.
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the destination starts consented.")

        // That cache is populated on a background queue. Without waiting, the gate still holds a
        // nil config and resolves fail-open, so the event would be delivered rather than dropped.
        let gate = try #require(plugin.pluginChain?.find(type: ConsentGatePlugin.self), "The destination chain must carry a consent gate.")
        let cached = await waitUntil { gate.destinationConfig != nil }
        #expect(cached, "Precondition: the gate must cache its destination config before the flip.")

        // The live event gate reads current state; no re-initialization happens here.
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["something-else"]))
        let result = plugin.intercept(event: makeTrackEvent(named: "dropped"))

        #expect(plugin.receivedTrackEventNames.isEmpty, "The gate must drop the event before delivery.")
        #expect((result as? TrackEvent)?.event == "dropped", "The event must still pass through unchanged for cloud delivery.")
    }

    @Test("given an event whose captured consent differs from the live state, when it is delivered, then the captured block survives")
    func testDeliveryRestoresCapturedConsentNotLiveState() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: nil), integration: plugin)

        // Created under a different decision from the one now in force.
        let capturedState = ConsentManagement(active: true, provider: .custom, allowedConsentIds: ["analytics"], deniedConsentIds: [])
        var track = TrackEvent(event: "pre-change")
        track.capturedReservedContext = [ConsentManagement.contextKey: capturedState.contextStamp]
        let event: Event = track.updateEventData()
            .addToContext(info: [ConsentManagement.contextKey: capturedState.contextStamp])

        _ = plugin.intercept(event: event)

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(
            block?["allowedConsentIds"] as? [String] == ["analytics"],
            "Delivery must not rewrite the event's record from live state."
        )
    }

    @Test("given a destination plugin rewriting the consent key on every event, when several are delivered, then only the first warns")
    func testDestinationChainOverrideWarnsOnce() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: nil), integration: plugin)
        plugin.add(plugin: ContextMutatingPlugin(info: ["consentManagement": ["provider": Self.sentinel]]))

        for index in 0..<3 {
            _ = plugin.intercept(event: makeTrackEvent(named: "spoofed-\(index)", for: analytics))
        }

        let warnings = mockLogger.logs.filter { $0.level == "WARN" && $0.message.contains("consentManagement") }
        #expect(warnings.count == 1, "A destination plugin rewriting the key must warn once per destination, not per event.")
        #expect(warnings.first?.message.contains("written by a plugin on destination \(plugin.key)") == true, "The warning must name the destination whose plugin wrote the key.")
        #expect(warnings.first?.message.contains("Migrate to setConsent(_:).") == true, "The warning must point at the supported way to supply consent.")
    }

    @Test("given a destination plugin revoking consent mid chain, when the event reaches the handoff, then it is not delivered")
    func testRevocationInsideDestinationChainStopsHandoff() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        // The event gate seeds its destination config from state at setup, so the config must be there first.
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the destination starts consented.")
        plugin.add(plugin: ConsentRevokingPlugin(options: ConsentManagementOptions(deniedConsentIds: ["marketing"])))

        _ = plugin.intercept(event: makeTrackEvent(named: "in-flight", for: analytics))

        #expect(plugin.receivedTrackEventNames.isEmpty, "A revocation landing after the event gate must still stop the handoff.")
    }

    @Test("given the source config tightens consent while an event is in the destination chain, when it reaches the handoff, then it is not delivered")
    func testTightenedSourceConfigInsideDestinationChainStopsHandoff() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the destination starts consented.")
        // The dashboard now demands a second consent the user has never granted.
        let tightened = makeSourceConfig(consentEntries: [gatedEntry(consents: ["marketing", "analytics"])])
        plugin.add(plugin: ConfigTighteningPlugin(sourceConfig: tightened, integration: plugin))

        _ = plugin.intercept(event: makeTrackEvent(named: "in-flight", for: analytics))

        #expect(plugin.receivedTrackEventNames.isEmpty, "The handoff must judge the event against the rules in force when it is handed over.")
    }

    @Test("given a destination with no consent rules, when consent is revoked mid chain, then the event is still delivered")
    func testRevocationInsideDestinationChainLeavesUngatedDestinationDelivering() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let sourceConfig = makeSourceConfig(consentEntries: nil)
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        plugin.add(plugin: ConsentRevokingPlugin(options: ConsentManagementOptions(deniedConsentIds: ["marketing"])))

        _ = plugin.intercept(event: makeTrackEvent(named: "ungated", for: analytics))

        #expect(plugin.receivedTrackEventNames == ["ungated"], "A destination with no consent rules is never gated.")
    }

    @Test("given a custom integration with consent rules, when consent is revoked while an event is mid chain, then it is not delivered")
    func testRevocationInsideCustomIntegrationChainStopsHandoff() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        let plugin = MockCustomIntegrationPlugin(key: destinationKey)
        plugin.setup(analytics: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the custom destination starts ready.")
        plugin.add(plugin: ConsentRevokingPlugin(options: ConsentManagementOptions(deniedConsentIds: ["marketing"])))

        _ = plugin.intercept(event: makeTrackEvent(named: "custom-in-flight", for: analytics))

        #expect(plugin.trackEventReceived == nil, "A custom integration matching a gated destination must be gated at the handoff too.")
    }

    @Test("given destination plugins that pass the event through a customer-defined event type across phases, when it is delivered, then the consent recorded at creation is delivered")
    func testCustomerEventTypeInDestinationChainKeepsRecordedConsent() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: nil), integration: plugin)
        plugin.add(plugin: MockCustomerEventSwappingPlugin(pluginType: .preProcess, contextInfo: ["consentManagement": ["provider": Self.sentinel]]))
        plugin.add(plugin: MockCustomerEventConvertingPlugin())

        _ = plugin.intercept(event: makeTrackEvent(named: "through-customer-type", for: analytics))

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "A block spoofed through a customer event type must not reach the destination.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])
    }

    // Device-mode delivery is one of the main chain's terminal consumers, so the recorded consent has to
    // survive a customer-defined event type there too, or the gate can no longer tell the event was created
    // while its destination was denied.
    @Test("given an event created while its destination was denied, when a customer plugin passes it through a customer-defined event type and consent is then granted, then it is not delivered")
    func testCustomerEventTypeInMainChainKeepsRecordedConsentForTheGate() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let capture = MockEventCapturePlugin()
        let chain = PluginChain(analytics: analytics)
        chain.add(plugin: MockCustomerEventSwappingPlugin(pluginType: .onProcess, contextInfo: [:]))
        chain.add(plugin: MockCustomerEventConvertingPlugin())
        chain.add(plugin: capture)
        chain.process(event: makeTrackEvent(named: "created-while-denied", for: analytics))
        guard let processed = capture.capturedEvents.first else {
            Issue.record("Precondition: the main chain must hand the event to its terminal consumers.")
            return
        }

        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the destination is consented after the grant.")

        _ = plugin.intercept(event: processed)

        #expect(plugin.receivedTrackEventNames.isEmpty, "An event created while the destination was denied must not be delivered after a grant.")
    }
}

// MARK: - Helpers
extension DeviceModeConsentRestampTests {

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

    private func makeIntegration(for analytics: Analytics) -> MockStandardIntegrationPlugin {
        let plugin = MockStandardIntegrationPlugin(key: destinationKey)
        plugin.setup(analytics: analytics)
        return plugin
    }

    private func makeTrackEvent(named name: String, options: RudderOption? = nil, for analytics: Analytics? = nil) -> Event {
        // Mirrors what Analytics.process does at creation: the event carries the consent decision in
        // force, which is what delivery restores from.
        var track = TrackEvent(event: name, options: options)
        track.capturedReservedContext = analytics?.capturedReservedContext()

        let event: Event = track.updateEventData()
        guard let state = analytics?.consentManagementState.value, state.active else { return event }
        return event.addToContext(info: [ConsentManagement.contextKey: state.contextStamp])
    }

    private func gatedEntry(consents: [String] = ["marketing"], strategy: String = "and") -> [String: Any] {
        [
            "provider": "custom",
            "consents": consents.map { ["consent": $0] },
            "resolutionStrategy": strategy
        ]
    }

    private func makeSourceConfig(consentEntries: [[String: Any]]?) -> SourceConfig {
        var destinationConfig: [String: AnyCodable] = ["apiKey": AnyCodable("mock-api-key")]
        if let consentEntries {
            destinationConfig["consentManagement"] = AnyCodable(consentEntries)
        }

        let destination = Destination(
            destinationId: "dest-1",
            destinationName: destinationKey,
            isDestinationEnabled: true,
            destinationConfig: destinationConfig,
            destinationDefinitionId: "def-1",
            destinationDefinition: DestinationDefinition(
                name: destinationKey,
                displayName: destinationKey
            ),
            updatedAt: "2026-01-01T00:00:00.000Z",
            shouldApplyDeviceModeTransformation: false,
            propagateEventsUntransformedOnError: true
        )

        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "source-id",
                sourceName: "source-name",
                writeKey: "write-key",
                isSourceEnabled: true,
                workspaceId: "workspace-id",
                updatedAt: "2026-01-01T00:00:00.000Z",
                metricConfig: MetricsConfig(),
                destinations: [destination]
            )
        )
    }
}

// MARK: - ContextMutatingPlugin
/**
 A customer-style plugin that merges the given values into the event context.
 */
private final class ContextMutatingPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    private let info: [String: Any]

    init(info: [String: Any]) {
        self.info = info
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: any Event) -> (any Event)? {
        event.addToContext(info: info)
    }
}

// MARK: - ConsentRevokingPlugin
/**
 A customer-style destination plugin that replaces the consent state while an event is inside the chain.
 */
private final class ConsentRevokingPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    private let options: ConsentManagementOptions

    init(options: ConsentManagementOptions) {
        self.options = options
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: any Event) -> (any Event)? {
        analytics?.setConsent(options)
        return event
    }
}

// MARK: - ConfigTighteningPlugin
/// Stands in for a source-config refresh landing while the event is inside the destination's own chain.
private final class ConfigTighteningPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    private let sourceConfig: SourceConfig
    private let integration: IntegrationPlugin

    init(sourceConfig: SourceConfig, integration: IntegrationPlugin) {
        self.sourceConfig = sourceConfig
        self.integration = integration
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: any Event) -> (any Event)? {
        analytics?.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: integration)
        return event
    }
}
