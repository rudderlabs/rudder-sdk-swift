//
//  ContextGuardPlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/26.
//

import Foundation

// MARK: - ContextGuardPlugin
/**
 A terminal plugin that re-asserts SDK-owned context keys after all customer plugins have run.

 Registered first in the `terminal` phase, so its re-stamped event flows into both delivery
 paths — the device-mode fan-out queue plus cloud-mode storage.
 */
final class ContextGuardPlugin: Plugin {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?

    func setup(analytics: Analytics) {
        self.analytics = analytics
    }

    func intercept(event: any Event) -> (any Event)? {
        // Base-key deprecation detection is independent of consent state; added separately.
        return self.enforceConsentStamp(on: event)
    }

    // MARK: - Consent Stamp
    /**
     Re-asserts `context.consentManagement` from the current consent state.

     Active only while consent management is enabled — while disabled the key is not
     reserved and the event passes through untouched.
     */
    private func enforceConsentStamp(on event: any Event) -> any Event {
        guard let state = self.analytics?.consentManagementState.value, state.enabled else { return event }

        let key = SDKManagedContextKey.consentManagement.rawValue
        guard event.context?[key] != AnyCodable(state.contextStamp) else { return event }

        self.analytics?.logger.warn(log: "ContextGuardPlugin: Replacing the \"consentManagement\" key found in the event context; the SDK owns this key while consent management is enabled. Migrate to setConsent(_:).")
        return event.addToContext(info: [key: state.contextStamp])
    }
}
