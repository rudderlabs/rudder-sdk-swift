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
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-init-1", for: analytics), to: plugin)
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-init-2", for: analytics), to: plugin)
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
            analytics?.integrationsController?.deliver(event: self.makeTrackEvent(named: "during-failed-init", for: analytics), to: plugin)
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
            controller?.deliver(event: self.makeTrackEvent(named: "during-first-create", for: analytics), to: second)
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

    // MARK: - The setConsent gap

    @Test("given a grant, when an event arrives before re-initialization is scheduled, then it is still delivered")
    func testEventBetweenSetConsentAndReinitIsDelivered() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        let controller = analytics.integrationsController
        controller?.add(integration: plugin)
        controller?.initDestination(sourceConfig: sourceConfig, integration: plugin)
        #expect(plugin.createCalled == false, "Precondition: the destination starts denied.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        // Re-initialization is scheduled asynchronously; this event lands before it runs.
        controller?.deliver(event: makeTrackEvent(named: "right-after-grant", for: analytics), to: plugin)
        controller?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.receivedTrackEventNames == ["right-after-grant"], "An event created after consent was granted must not be lost to the gap before re-initialization is scheduled.")
    }

    @Test("given events created before a grant, when they drain after it, then they are never held")
    func testEventsCreatedBeforeTheGrantAreNeverHeld() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        let plugin = makeIntegration(for: analytics)
        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        let controller = analytics.integrationsController
        controller?.add(integration: plugin)
        controller?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        // Created while the destination was denied, still queued upstream when consent is granted.
        let queuedBeforeGrant = makeTrackEvent(named: "queued-before-grant")
        Thread.sleep(forTimeInterval: 0.01)
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))

        controller?.deliver(event: queuedBeforeGrant, to: plugin)
        controller?.initDestination(sourceConfig: sourceConfig, integration: plugin)

        #expect(plugin.createCalled == true, "Precondition: the grant late-initializes the destination.")
        #expect(plugin.receivedTrackEventNames.isEmpty, "An event's consent verdict is fixed when it happens; holding from the grant onward must not reach back and deliver events that occurred while consent was denied.")
    }

    @Test("given consent supplied at launch, when an event arrives before the destination is created, then it is held")
    func testColdStartHoldsEventsCreatedAfterLaunch() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let plugin = makeIntegration(for: analytics)
        let controller = analytics.integrationsController
        // Created after launch but before the destination exists — the ordinary cold-start case.
        let earlyEvent = makeTrackEvent(named: "early-event", for: analytics)
        Thread.sleep(forTimeInterval: 0.01)

        plugin.onCreate = { [weak controller, weak plugin] in
            guard let plugin else { return }
            controller?.deliver(event: earlyEvent, to: plugin)
        }
        controller?.initDestination(sourceConfig: makeSourceConfig(consentEntries: [gatedEntry()]), integration: plugin)

        #expect(plugin.receivedTrackEventNames == ["early-event"], "Consent from the configuration is decided at launch, so the cutoff is launch — not the moment the hold happens to open, which would discard everything sent while the SDK was starting up.")
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
            controller?.deliver(event: self.makeTrackEvent(named: "during-create", for: analytics), to: plugin)
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

    // MARK: - Gate configuration seeding

    // The gate caches its destination config from a stream that delivers on a background queue, so
    // whether it is ready for its first event is a race. Only the gate is rebuilt per iteration —
    // rebuilding the SDK too would give that background delivery time to land and hide the race.
    @Test("given the source config already arrived, when a gate is set up, then its first event is gated")
    func testGateDropsFirstEventWithoutWaiting() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["something-else"]))
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: makeSourceConfig(consentEntries: [gatedEntry()])))

        for iteration in 0..<50 {
            // Built before setup: constructing an event is enough work to let the background
            // delivery land, which would close the very window this test exists to hold open.
            let event = makeTrackEvent(named: "first")

            let gate = ConsentGatePlugin(key: destinationKey)
            gate.setup(analytics: analytics)

            #expect(gate.intercept(event: event) == nil, "A consent-denied destination must gate its very first event with no wait (iteration \(iteration)).")
        }
    }

    // Covers the late-registration path itself, which had no coverage. It does not pin the seeding
    // race: `add` and `setConsent` take long enough that the background delivery has landed by the
    // time the event is sent, so this passes with or without the synchronous seed.
    @Test("given a destination registered after the source config, when consent is revoked, then it stops receiving events")
    func testLateRegisteredDestinationIsGatedAfterRevoke() {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let controller = analytics.integrationsController
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: makeSourceConfig(consentEntries: [gatedEntry()])))
        controller?.isSourceEnabledFetchedAtLeastOnce = true

        // add(plugin:) after the source config arrived — the controller creates it right here.
        let plugin = makeIntegration(for: analytics)
        controller?.add(integration: plugin)
        #expect(plugin.createCalled == true, "Precondition: a late-added destination is created immediately.")

        analytics.setConsent(ConsentManagementOptions(deniedConsentIds: ["marketing"]))

        _ = plugin.intercept(event: makeTrackEvent(named: "after-revoke", for: analytics))

        #expect(plugin.receivedTrackEventNames.isEmpty, "A revoked destination must gate its events even when it was registered late.")
    }

    // MARK: - Delivery once the destination is ready

    // Driven through the public API end to end, because the leak this pins needs three moving parts
    // in the right order: an event created under the denied state, a destination that becomes ready
    // while that event is held, and a customer plugin releasing it afterwards.
    @Test("given a customer plugin holding an event from the denied period, when it releases after the destination is ready, then only the post-grant event is delivered")
    func testHeldPreGrantEventIsNotDeliveredOnceTheDestinationIsReady() async throws {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["analytics"]))
        let holder = EventHoldingPlugin(holding: "denied-before-grant")
        analytics.add(plugin: holder)

        let plugin = MockStandardIntegrationPlugin(key: destinationKey)
        analytics.add(plugin: plugin)

        let sourceConfig = makeSourceConfig(consentEntries: [gatedEntry()])
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))
        let configLanded = await waitUntil { analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == true }
        #expect(configLanded, "Precondition: the source config must land before events are processed.")
        #expect(plugin.createCalled == false, "Precondition: the destination is consent-denied at launch.")

        // Created while consent was denied, then held in the chain by the customer's plugin.
        analytics.track(name: "denied-before-grant")
        let holding = await waitUntil { holder.isHolding }
        #expect(holding, "Precondition: the customer plugin must be holding the event.")

        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        let ready = await waitUntil { plugin.pluginStore?.isDestinationReady == true }
        #expect(ready, "Precondition: the grant must re-initialize the destination before the held event resumes.")

        holder.release()
        analytics.track(name: "after-grant")

        // The held event was released first, so once the later one lands the earlier one has been decided.
        let delivered = await waitUntil { plugin.receivedTrackEventNames.contains("after-grant") }
        #expect(delivered, "Precondition: an event created after the grant must reach the destination.")
        #expect(plugin.receivedTrackEventNames == ["after-grant"], "An event created while consent was denied must not be delivered, however late it is released.")
    }

    // The revoke-then-grant cycle reaches readiness through `safelyUpdateAndNotify`, which never
    // opens a hold itself — the destination instance outlives the revoke, so re-initialization takes
    // the update path. What keeps the boundary is that every re-initialization is preceded by
    // `beginBufferingForPendingDestinations`. This pins that, because the update path would
    // otherwise mark a destination ready with no consent boundary at all.
    @Test("given a destination revoked then granted again, when an event from the denied window is released late, then it is not delivered")
    func testEventFromTheDeniedWindowIsNotDeliveredAfterRegrant() async throws {
        let analytics = makeAnalytics(consent: ConsentManagementConfiguration(enabled: true, allowedConsentIds: ["marketing"]))
        let holder = EventHoldingPlugin(holding: "denied-window")
        analytics.add(plugin: holder)

        let plugin = MockStandardIntegrationPlugin(key: destinationKey)
        analytics.add(plugin: plugin)

        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: makeSourceConfig(consentEntries: [gatedEntry()])))
        let configLanded = await waitUntil { analytics.integrationsController?.isSourceEnabledFetchedAtLeastOnce == true }
        #expect(configLanded, "Precondition: the source config must land before events are processed.")
        #expect(plugin.createCalled == true, "Precondition: the destination is consented at launch, so it is created.")

        // Revoke: torn down, but the destination instance survives.
        analytics.setConsent(ConsentManagementOptions(deniedConsentIds: ["marketing"]))
        let notReady = await waitUntil { plugin.pluginStore?.isDestinationReady == false }
        #expect(notReady, "Precondition: revoking consent must stop the destination delivering.")

        // Created during the denied window, then parked by the customer plugin.
        analytics.track(name: "denied-window")
        let holding = await waitUntil { holder.isHolding }
        #expect(holding, "Precondition: the customer plugin must be holding the denied-window event.")

        // Grant again: the surviving instance takes the update path.
        analytics.setConsent(ConsentManagementOptions(allowedConsentIds: ["marketing"]))
        let ready = await waitUntil { plugin.pluginStore?.isDestinationReady == true }
        #expect(ready, "Precondition: granting again must make the destination ready.")
        #expect(plugin.updateCalled == true, "Precondition: the surviving instance re-initializes through the update path, not create.")

        holder.release()
        analytics.track(name: "after-grant")
        let delivered = await waitUntil { plugin.receivedTrackEventNames.contains("after-grant") }
        #expect(delivered, "Precondition: an event created after the grant must reach the destination.")

        #expect(plugin.receivedTrackEventNames == ["after-grant"], "An event created while consent was revoked must not be delivered after the destination is granted again.")
    }

}

// MARK: - EventHoldingPlugin
/// Stands in for a customer plugin that parks one event and releases it later.
private final class EventHoldingPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?

    @Synchronized private(set) var isHolding = false

    private let heldEventName: String
    private let gate = DispatchSemaphore(value: 0)

    init(holding eventName: String) {
        self.heldEventName = eventName
    }

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: Event) -> Event? {
        guard (event as? TrackEvent)?.event == heldEventName else { return event }

        self.isHolding = true
        // Bounded, so a test that never releases fails on its expectations instead of hanging.
        _ = gate.wait(timeout: .now() + 5)
        self.isHolding = false
        return event
    }

    func release() {
        gate.signal()
    }
}

// MARK: - Helpers
extension ConsentGatingTests {

    /// Polls until `condition` holds or the timeout elapses, returning whether it held. Tests assert
    /// on the result rather than hanging, so a broken precondition fails with its own message.
    private func waitUntil(timeout: TimeInterval = 2.0, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: MockStorage.pollInterval)
        }
        return condition()
    }

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

    private func makeTrackEvent(named name: String, for analytics: Analytics? = nil) -> Event {
        // Mirrors what Analytics.process does at creation: the event carries the consent decision in
        // force, which is what the device-mode hold compares against. These tests hand events to the
        // controller directly, so without this they would all sit at epoch zero and be skipped.
        var track = TrackEvent(event: name)
        track.consentEpoch = analytics?.consentEpoch ?? 0

        var event: Event = track.updateEventData()
        if let state = analytics?.consentManagementState.value, state.enabled {
            event = event.addToContext(info: [ConsentManagement.contextKey: state.contextStamp])
        }
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
