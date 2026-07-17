//
//  EventFilteringPluginLateSubscriberTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 17/07/26.
//

import Testing
import Foundation
@testable import RudderStackAnalytics

/**
 Guards the ordering bug where an integration added after the source config had already been
 dispatched left its `EventFilteringPlugin` unconfigured, silently forwarding denied events.
 */
@Suite("EventFiltering Plugin Late Subscriber Tests")
struct EventFilteringPluginLateSubscriberTests {

    /// "Bing Ads" in mock_source_config.json uses eventFilteringOption = "whitelistedEvents".
    private let destinationKey = "Bing Ads"
    private let whitelistedEvent = "form_submit"
    private let nonWhitelistedEvent = "Track Event 3"

    /// Returns an analytics instance whose own cached/network source config fetch has settled,
    /// so that any dispatch afterwards is the one under test.
    private func settledAnalytics() async -> Analytics {
        let analytics = MockProvider.createMockAnalytics()
        await runAfter(1.0) {}
        return analytics
    }

    @Test("Given a source config dispatched before setup, When a track event is intercepted, Then filtering is applied")
    func testLateSubscriberAppliesFiltering() async {
        let analytics = await settledAnalytics()
        guard let sourceConfig = MockProvider.sourceConfiguration else {
            #expect(Bool(false), "sourceConfiguration is nil")
            return
        }

        // Source config is already in the state before the plugin subscribes, which is what happens
        // when an integration is added after the source config has been fetched.
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))

        let plugin = EventFilteringPlugin(key: destinationKey)
        plugin.setup(analytics: analytics)

        await runAfter(0.5) {
            #expect(plugin.intercept(event: TrackEvent(event: whitelistedEvent)) != nil, "whitelisted event must pass through")
            #expect(plugin.intercept(event: TrackEvent(event: nonWhitelistedEvent)) == nil, "non-whitelisted event must be dropped")
        }
    }

    @Test("Given a late subscriber and an identical refresh, When a track event is intercepted, Then filtering is still applied")
    func testLateSubscriberWithIdenticalRefreshAppliesFiltering() async {
        let analytics = await settledAnalytics()
        guard let sourceConfig = MockProvider.sourceConfiguration else {
            #expect(Bool(false), "sourceConfiguration is nil")
            return
        }

        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))

        let plugin = EventFilteringPlugin(key: destinationKey)
        plugin.setup(analytics: analytics)

        // A refresh returning an identical config is de-duplicated on updatedAt, so the plugin must
        // already be configured from the value it received on subscription.
        await runAfter(0.2) {}
        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))

        await runAfter(0.5) {
            #expect(plugin.intercept(event: TrackEvent(event: nonWhitelistedEvent)) == nil, "non-whitelisted event must be dropped")
        }
    }

    @Test("Given a subscriber present before dispatch, When a track event is intercepted, Then filtering is applied")
    func testEarlySubscriberAppliesFiltering() async {
        let analytics = await settledAnalytics()
        guard let sourceConfig = MockProvider.sourceConfiguration else {
            #expect(Bool(false), "sourceConfiguration is nil")
            return
        }

        let plugin = EventFilteringPlugin(key: destinationKey)
        plugin.setup(analytics: analytics)

        analytics.sourceConfigState.dispatch(action: UpdateSourceConfigAction(updatedSourceConfig: sourceConfig))

        await runAfter(0.5) {
            #expect(plugin.intercept(event: TrackEvent(event: whitelistedEvent)) != nil, "whitelisted event must pass through")
            #expect(plugin.intercept(event: TrackEvent(event: nonWhitelistedEvent)) == nil, "non-whitelisted event must be dropped")
        }
    }
}
