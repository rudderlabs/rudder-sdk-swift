//
//  ConsentGatingTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/08/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

@Suite("Consent Gating Tests")
struct ConsentGatingTests {

    private let destinationKey = "MockDestination"

    // MARK: - Initialization gate

    @Test("given a denied destination, when initialized, then create is never invoked with a consent-denied callback plus warning")
    func testDeniedDestinationIsNeverCreated() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]), logger: mockLogger)
        let plugin = makeIntegration(for: analytics)
        var receivedResult: DestinationResult?
        plugin.onDestinationReady { _, result in receivedResult = result }

        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.createCalled == false, "A consent-denied destination must never be created.")
        guard case .failure(let error) = receivedResult, case DestinationError.destinationConsentDenied = error else {
            Issue.record("The ready-callback must resolve with destinationConsentDenied.")
            return
        }
        let warnings = mockLogger.logs.filter { $0.level == "WARN" }
        #expect(warnings.contains { $0.message.contains("denied by user consent") }, "The warning must name the denial.")
        #expect(warnings.allSatisfy { !$0.message.contains("marketing") }, "Warnings must never contain consent ID values.")
    }

    @Test("given consent management disabled, when a gated destination is initialized, then behavior is identical to the current release")
    func testDisabledBehavesAsCurrentRelease() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false))
        let plugin = makeIntegration(for: analytics)

        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)
        _ = plugin.intercept(event: makeTrackEvent(named: "regular-event"))

        #expect(plugin.createCalled == true, "Disabled consent management must never gate initialization.")
        #expect(plugin.pluginStore?.isDestinationReady == true)
        #expect(plugin.receivedTrackEventNames == ["regular-event"], "Delivery must be untouched while disabled.")
    }

    // MARK: - Grant mid-session

    @Test("given a grant mid-session, when the destination late-initializes, then events arriving during the init window are replayed in order")
    func testGrantReplaysBufferedEventsInOrder() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.createCalled == false, "Precondition: the destination starts denied.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        plugin.onCreate = { [weak analytics] in
            analytics?.integrationsController?.bufferIfReinitializing(event: self.makeTrackEvent(named: "during-init-1"), key: self.destinationKey)
            analytics?.integrationsController?.bufferIfReinitializing(event: self.makeTrackEvent(named: "during-init-2"), key: self.destinationKey)
        }
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.createCalled == true, "The grant must late-initialize the destination.")
        #expect(plugin.pluginStore?.isDestinationReady == true)
        #expect(plugin.receivedTrackEventNames == ["during-init-1", "during-init-2"], "Buffered events must replay in arrival order once the destination is ready.")
    }

    @Test("given events sent while denied, when the destination later initializes, then pre-grant events are never replayed")
    func testPreGrantEventsAreNeverReplayed() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        _ = plugin.intercept(event: makeTrackEvent(named: "pre-grant-event"))
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.createCalled == true)
        #expect(plugin.receivedTrackEventNames.isEmpty, "An event's consent verdict is fixed at creation — pre-grant events must never be replayed.")
    }

    @Test("given a failed late initialization, when the buffer is discarded, then a warning is logged with no stale delivery")
    func testFailedInitDiscardsBuffer() {
        let mockLogger = MockLogger()
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]), logger: mockLogger)
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        plugin.createThrowsError = MockIntegrationError.createFailed
        plugin.onCreate = { [weak analytics] in
            analytics?.integrationsController?.bufferIfReinitializing(event: self.makeTrackEvent(named: "during-failed-init"), key: self.destinationKey)
        }

        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.receivedTrackEventNames.isEmpty, "A failed init must discard the buffer, not deliver it.")
        #expect(mockLogger.logs.contains { $0.level == "WARN" && $0.message.contains("Discarded 1 buffered") }, "The discard must be logged as a value-free warning.")

        // A later successful init must not resurrect the discarded events.
        plugin.createThrowsError = nil
        plugin.onCreate = nil
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.receivedTrackEventNames.isEmpty, "Discarded events must never reappear on a later successful init.")
    }

    // MARK: - Revoke mid-session

    @Test("given a revoke mid-session, when re-evaluated, then zero further events reach the destination")
    func testRevokeStopsDelivery() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        _ = plugin.intercept(event: makeTrackEvent(named: "before-revoke"))
        #expect(plugin.receivedTrackEventNames == ["before-revoke"], "Precondition: the consented destination delivers.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["something-else"]))
        analytics.integrationsController?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        _ = plugin.intercept(event: makeTrackEvent(named: "after-revoke"))

        #expect(plugin.receivedTrackEventNames == ["before-revoke"], "After a revoke, zero further events may reach the destination.")
    }

    // MARK: - Cloud mode

    @Test("given a denied destination, when an event is intercepted, then it passes through unchanged for cloud delivery")
    func testDeniedDestinationPassesEventThrough() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)
        let event = makeTrackEvent(named: "cloud-bound-event")

        let result = plugin.intercept(event: event)

        #expect((result as? TrackEvent)?.event == "cloud-bound-event", "Device-mode gating must return the event unchanged — cloud delivery is unaffected.")
        #expect(plugin.receivedTrackEventNames.isEmpty, "The denied destination itself must receive nothing.")
    }
}

// MARK: - Helpers
extension ConsentGatingTests {

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

    private func makeTrackEvent(named name: String) -> Event {
        var event: Event = TrackEvent(event: name)
        event = event.updateEventData()
        return event
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
