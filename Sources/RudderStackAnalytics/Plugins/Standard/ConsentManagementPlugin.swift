//
//  ConsentManagementPlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 14/08/26.
//

import Foundation

// MARK: - ConsentManagementPlugin
/**
 A plugin that stamps the current consent state into `context.consentManagement` on every event.
 
 While consent management is enabled, the complete block — `provider`, `allowedConsentIds` and `deniedConsentIds` — is written on each event, replacing any value injected via custom context. While disabled, events pass through untouched, so a legacy customContext injection keeps working. The block written is the one captured when the event was created, not the state at this instant, so a decision taken while the event is in flight cannot rewrite what the event recorded; `SchemaGuardPlugin` re-asserts that same captured value at the terminal boundary.
 
 A customer still injecting the key does so on every event, so the replacement is warned about once per analytics instance rather than once per event.
 */

final class ConsentManagementPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    // Events are intercepted concurrently, so the first-warning check has to be atomic - a plain
    // flag would let two events both warn.
    @Synchronized private var hasWarnedAboutInjectedKey = false
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        let consentKey = ConsentManagement.contextKey
        guard let captured = (event as? ReservedContextCapturing)?.capturedReservedContext?[consentKey] else {
            return event
        }
        
        if event.context?[consentKey] != nil, self.claimFirstWarning() {
            self.analytics?.logger.warn(log: "ConsentManagementPlugin: Replacing the \"consentManagement\" key found in the event context; the SDK owns this key while consent management is enabled. Migrate to setConsent(_:).")
        }
        
        return event.addToContext(info: [consentKey: captured])
    }
    
    /// Claims the single warning, returning `true` exactly once per instance.
    private func claimFirstWarning() -> Bool {
        var claimed = false
        self.$hasWarnedAboutInjectedKey.modify { warned in
            claimed = !warned
            warned = true
        }
        return claimed
    }
}
