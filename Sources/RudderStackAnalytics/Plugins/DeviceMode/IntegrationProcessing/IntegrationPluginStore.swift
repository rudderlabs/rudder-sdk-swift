//
//  IntegrationPluginStore.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation

/**
 Stores the state of an integration plugin
 */
class IntegrationPluginStore {
    var analytics: Analytics?
    var pluginChain: PluginChain?
    @Synchronized var destinationReadyCallbacks: [IntegrationCallback] = []
    var isStandardIntegration: Bool = true
    /// Lifecycle state for flush, reset and readiness callbacks. Delivery is not gated on this —
    /// `DestinationDeliveryControl` decides that, so readiness and any hold cannot disagree.
    var isDestinationReady = false
    /// The destination's consent rules, kept for the handoff gate so it costs no source-config lookup
    /// per event.
    @Synchronized var destinationConfig: [String: Any]?
    /// Claimed once per destination, so a destination plugin rewriting the consent key warns once
    /// rather than on every event.
    @Synchronized private var hasWarnedAboutRestoredStamp = false

    init(analytics: Analytics) {
        self.analytics = analytics
        self.pluginChain = PluginChain(analytics: analytics)
    }

    /// Claims the single restore warning, returning `true` exactly once per destination.
    func claimRestoreWarning() -> Bool {
        var claimed = false
        self.$hasWarnedAboutRestoredStamp.modify { warned in
            claimed = !warned
            warned = true
        }
        return claimed
    }
    
    deinit {
        self.pluginChain?.removeAll()
        self.pluginChain = nil
        self.destinationReadyCallbacks.removeAll()
    }
}
