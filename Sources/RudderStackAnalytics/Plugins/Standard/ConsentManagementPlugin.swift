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
 
 While consent management is enabled, the complete block — `provider`, `allowedConsentIds` and
 `deniedConsentIds` — is written on each event, replacing any value injected via custom context.
 While disabled, events pass through untouched, so a legacy customContext injection keeps working.
 The stamp reflects the state at event creation; events already in the pipeline are not restamped.
 
 A customer still injecting the key does so on every event, so the replacement is warned about once
 per analytics instance rather than once per event.
 */

final class ConsentManagementPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    private static let consentManagementKey = "consentManagement"
    
    // Events are intercepted concurrently, so the first-warning check has to be atomic - a plain
    // flag would let two events both warn.
    @Synchronized private var hasWarnedAboutInjectedKey = false
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let state = self.analytics?.consentManagementState.value, state.active else {
            return event
        }
        
        if event.context?[Self.consentManagementKey] != nil, self.claimFirstWarning() {
            self.analytics?.logger.warn(log: "ConsentManagementPlugin: Replacing the \"consentManagement\" key found in the event context; the SDK owns this key while consent management is enabled. Migrate to setConsent(_:).")
        }
        
        return event.addToContext(info: [Self.consentManagementKey: self.preparedConsentBlock(from: state)])
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
    
    private func preparedConsentBlock(from state: ConsentManagement) -> [String: Any] {
        return [
            "provider": state.provider.value,
            "allowedConsentIds": state.allowedConsentIds,
            "deniedConsentIds": state.deniedConsentIds
        ]
    }
}
