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
        _ = plugin.intercept(event: makeTrackEvent(named: "with-injection", options: options))

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

        _ = plugin.intercept(event: makeTrackEvent(named: "spoofed"))

        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["provider"] as? String == "custom", "The restamp must run after the destination's own plugin chain.")
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"])
    }

    @Test("given buffered events replayed after a grant, when delivered, then each carries the current consent stamp")
    func testReplayedEventsCarryCurrentStamp() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.createCalled == false, "Precondition: the destination starts denied.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        plugin.onCreate = { [weak analytics] in
            analytics?.integrationsController?.bufferIfReinitializing(event: self.makeTrackEvent(named: "during-init"), key: self.destinationKey)
        }
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.receivedTrackEventNames == ["during-init"], "Precondition: the buffered event must replay.")
        let block = plugin.trackEventReceived?.context?.rawDictionary["consentManagement"] as? [String: Any]
        #expect(block?["allowedConsentIds"] as? [String] == ["marketing"], "A replayed event must carry the consent state it is delivered under.")
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

    private func makeTrackEvent(named name: String, options: RudderOption? = nil) -> Event {
        let event: Event = TrackEvent(event: name, options: options)
        return event.updateEventData()
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
