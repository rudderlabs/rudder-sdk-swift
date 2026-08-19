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
 */

final class ConsentManagementPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    private static let consentManagementKey = SDKManagedContextKey.consentManagement.rawValue
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let state = self.analytics?.consentManagementState.value, state.enabled else {
            return event
        }
        
        if event.context?[Self.consentManagementKey] != nil {
            self.analytics?.logger.warn(log: "ConsentManagementPlugin: Replacing the \"consentManagement\" key found in the event context; the SDK owns this key while consent management is enabled. Migrate to setConsent(_:).")
        }
        
        return event.addToContext(info: [Self.consentManagementKey: state.contextStamp])
    }
}
