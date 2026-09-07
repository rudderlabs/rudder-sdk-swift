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

    @Test("given a denied destination whose update rejects an empty config, when initialized, then the consent reason still reaches the callback")
    func testDeniedDestinationReportsConsentReasonNotUpdateError() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        plugin.updateThrowsError = MockIntegrationError.configurationMissing
        var receivedResult: DestinationResult?
        plugin.onDestinationReady { _, result in receivedResult = result }

        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.updateCalled == false, "A destination being declared failed must never be updated.")
        guard case .failure(let error) = receivedResult, case DestinationError.destinationConsentDenied = error else {
            Issue.record("The denial reason must survive; an update failure must not replace it.")
            return
        }
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
        plugin.onCreate = { [weak analytics, weak plugin] in
            guard let plugin else { return }
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-init-1"), to: plugin)
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-init-2"), to: plugin)
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
        plugin.onCreate = { [weak analytics, weak plugin] in
            guard let plugin else { return }
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-failed-init"), to: plugin)
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

    @Test("given two denied destinations, when a grant re-initializes them, then the second holds events while the first is still creating")
    func testSecondDestinationHoldsWhileFirstIsStillCreating() {
        let firstKey = "FirstDestination"
        let secondKey = "SecondDestination"
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let first = makeIntegration(for: analytics, key: firstKey)
        let second = makeIntegration(for: analytics, key: secondKey)
        let sourceConfig = makeSourceConfig(for: [firstKey, secondKey], consentEntries: [gatedEntry()])
        let controller = analytics.integrationsController
        // Registered on the chain, which is what the pending-hold pass walks.
        controller?.add(integration: first)
        controller?.add(integration: second)

        controller?.beginBufferingForPendingDestinations()
        controller?.initDestination(sourceConfig: sourceConfig, integration: first)
        controller?.initDestination(sourceConfig: sourceConfig, integration: second)
        #expect(first.createCalled == false && second.createCalled == false, "Precondition: both destinations start denied.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        // An event bound for the second destination arrives while the first is still inside create().
        first.onCreate = { [weak controller, weak second] in
            guard let second else { return }
            controller?.deliver(event: self.makeTrackEvent(named: "during-first-create"), to: second)
        }

        controller?.beginBufferingForPendingDestinations()
        controller?.initDestination(sourceConfig: sourceConfig, integration: first)
        controller?.initDestination(sourceConfig: sourceConfig, integration: second)

        #expect(second.receivedTrackEventNames == ["during-first-create"], "Every pending destination must start holding before any of them is initialized; otherwise the second loses whatever arrives while the first is still creating.")
    }

    @Test("given a delivering destination, when a consent change re-evaluates it, then it keeps delivering")
    func testReadyDestinationIsNotPutOnHold() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: the destination is already delivering.")

        analytics.integrationsController?.beginBufferingForPendingDestinations()
        _ = plugin.intercept(event: makeTrackEvent(named: "after-reevaluation"))

        #expect(plugin.receivedTrackEventNames == ["after-reevaluation"], "A re-evaluation must not interrupt a destination that is already delivering.")
    }

    @Test("given an already created custom integration, when a consent change re-evaluates it, then it is not left holding events")
    func testAlreadyCreatedCustomIntegrationIsNotLeftHolding() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeCustomIntegration(for: analytics)
        analytics.integrationsController?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)
        #expect(plugin.pluginStore?.isDestinationReady == true, "Precondition: custom integrations are never gated, so this one is delivering.")

        analytics.integrationsController?.beginBufferingForPendingDestinations()
        _ = plugin.intercept(event: makeTrackEvent(named: "after-reevaluation"))

        #expect(plugin.trackEventReceived?.event == "after-reevaluation", "Re-initializing a created custom integration is a no-op, so a hold opened for it would never be released.")
    }

    // MARK: - Consent inactive

    @Test("given consent management disabled, when an event arrives during create, then it is skipped as before")
    func testConsentDisabledDoesNotHoldEventsDuringCreate() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: false))
        let plugin = makeIntegration(for: analytics)
        let controller = analytics.integrationsController
        plugin.onCreate = { [weak controller, weak plugin] in
            guard let plugin else { return }
            controller?.deliver(event: self.makeTrackEvent(named: "during-create"), to: plugin)
        }

        controller?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.createCalled == true, "Precondition: with consent off the destination is created normally.")
        #expect(plugin.receivedTrackEventNames.isEmpty, "A customer who never enabled consent management must see the delivery behaviour they had before it existed.")
    }

    @Test("given consent management active, when an event arrives during create, then it is held and delivered")
    func testConsentEnabledHoldsEventsDuringCreate() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        let controller = analytics.integrationsController
        plugin.onCreate = { [weak controller, weak plugin] in
            guard let plugin else { return }
            controller?.deliver(event: self.makeTrackEvent(named: "during-create"), to: plugin)
        }

        controller?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.receivedTrackEventNames == ["during-create"], "With consent active the hold must still cover start-up; narrowing it must not reach the consent path.")
    }

    @Test("given consent enabled without any consent IDs, when an event arrives during create, then it is skipped like a disabled session")
    func testInactiveConsentBehavesLikeConsentDisabled() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true))
        let plugin = makeIntegration(for: analytics)
        let controller = analytics.integrationsController
        plugin.onCreate = { [weak controller, weak plugin] in
            guard let plugin else { return }
            controller?.deliver(event: self.makeTrackEvent(named: "during-create"), to: plugin)
        }

        controller?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.receivedTrackEventNames.isEmpty, "Enabled with no consent IDs is inactive for the session, so it must be indistinguishable from never having enabled consent — reading the supplied configuration instead of the resolved state would diverge here.")
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
    @Test("given a torn-down gate, when the source config changes, then the cached destination config is no longer updated")
    func testTeardownCancelsTheConfigSubscription() async {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = ConsentGatePlugin(key: destinationKey)
        plugin.setup(analytics: analytics)

        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: makeSourceConfig(consentEntries: [gatedEntry()])))
        await runAfter(0.2) {
            #expect(plugin.intercept(event: makeTrackEvent(named: "before")) == nil, "Precondition: the gate drops events while the destination is consent-denied.")
        }

        plugin.teardown()
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: makeSourceConfig(consentEntries: nil)))

        await runAfter(0.2) {
            #expect(plugin.intercept(event: makeTrackEvent(named: "after")) == nil, "After teardown the subscription must be cancelled, so the ungated config never lands and the stale denial still applies.")
        }
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

    private func makeIntegration(for analytics: Analytics, key: String? = nil) -> MockStandardIntegrationPlugin {
        let plugin = MockStandardIntegrationPlugin(key: key ?? destinationKey)
        plugin.setup(analytics: analytics)
        return plugin
    }

    private func makeCustomIntegration(for analytics: Analytics) -> MockCustomIntegrationPlugin {
        let plugin = MockCustomIntegrationPlugin(key: destinationKey)
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
        makeSourceConfig(for: [destinationKey], consentEntries: consentEntries)
    }

    private func makeSourceConfig(for keys: [String], consentEntries: [[String: Any]]?) -> SourceConfig {
        var destinationConfig: [String: AnyCodable] = ["apiKey": AnyCodable("mock-api-key")]
        if let consentEntries {
            destinationConfig["consentManagement"] = AnyCodable(consentEntries)
        }

        let destinations = keys.enumerated().map { index, key in
            Destination(
                destinationId: "dest-\(index + 1)",
                destinationName: key,
                isDestinationEnabled: true,
                destinationConfig: destinationConfig,
                destinationDefinitionId: "def-\(index + 1)",
                destinationDefinition: DestinationDefinition(
                    name: key,
                    displayName: key
                ),
                updatedAt: "2026-01-01T00:00:00.000Z",
                shouldApplyDeviceModeTransformation: false,
                propagateEventsUntransformedOnError: true
            )
        }

        return SourceConfig(
            source: RudderServerConfigSource(
                sourceId: "source-id",
                sourceName: "source-name",
                writeKey: "write-key",
                isSourceEnabled: true,
                workspaceId: "workspace-id",
                updatedAt: "2026-01-01T00:00:00.000Z",
                metricConfig: MetricsConfig(),
                destinations: destinations
            )
        )
    }
}
