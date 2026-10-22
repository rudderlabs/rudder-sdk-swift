//
//  IntegrationPluginStore.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation

/**
 The lifecycle of a destination.
 */
enum DestinationState {
    /// The next valid config calls `create`. The destination was never created, `create` failed, or the app removed
    /// the integration.
    case pendingCreate
    /// The destination is ready for flush, reset and readiness callbacks.
    case ready
    /// Created, but absent or disabled in the dashboard, denied by consent, or `update` failed.
    case paused
}

/**
 Stores the state of an integration plugin
 */
class IntegrationPluginStore {
    var analytics: Analytics?
    var pluginChain: PluginChain?
    @Synchronized var destinationReadyCallbacks: [IntegrationCallback] = []
    /// The last result reported to the callbacks. Read and write it only inside `$destinationReadyCallbacks.modify`.
    var lastResult: DestinationResult?
    var isStandardIntegration: Bool = true
    /// Lifecycle state for create or update, flush, reset and readiness callbacks. Delivery is not gated on this —
    /// `DestinationDeliveryControl` decides that, so readiness and any hold cannot disagree.
    @Synchronized var destinationState: DestinationState = .pendingCreate
    var isDestinationReady: Bool { destinationState == .ready }
    /// The destination's consent rules, kept for the handoff gate so it costs no source-config lookup
    /// per event.
    @Synchronized var destinationConfig: [String: Any]?
    /// Claimed once per destination, so a destination plugin rewriting the consent key warns once
    /// rather than on every event.
    @Synchronized private var hasWarnedAboutRestoredStamp = false

    /// Marks the destination not ready. A destination that `create` never set up stays `pendingCreate`, so the next
    /// valid config still calls `create`.
    func markNotReady() {
        $destinationState.modify { state in
            if state != .pendingCreate { state = .paused }
        }
    }

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
