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
    
    private let snapshotPlugin: ContextSnapshotPlugin
    
    init(snapshotPlugin: ContextSnapshotPlugin) {
        self.snapshotPlugin = snapshotPlugin
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        self.warnOnBaseKeyOverrides(on: event)
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

// MARK: - Base Key Detection

extension ContextGuardPlugin {
    /**
     Logs a value-free deprecation warning for each SDK-stamped base key carrying a
     customer-supplied value — injected via `RudderOption.customContext` or written by a
     customer plugin (detected against the snapshot). Detection only: the event is never
     modified, so existing overrides keep working unchanged.
     */
    
    private func warnOnBaseKeyOverrides(on event: any Event) {
        var overriddenKeys = Set<String>()
        
        if let customContext = event.options?.customContext {
            for key in SDKManagedContextKey.baseKeys where customContext.keys.contains(key.rawValue) {
                overriddenKeys.insert(key.rawValue)
            }
        }
        
        if let snapshot = self.snapshotPlugin.consumeSnapshot(for: event.messageId) {
            for key in SDKManagedContextKey.baseKeys where !isSameValue(event.context?[key.rawValue], snapshot[key.rawValue]) {
                overriddenKeys.insert(key.rawValue)
            }
        }

        for key in SDKManagedContextKey.baseKeys where overriddenKeys.contains(key.rawValue) {
            self.analytics?.logger.warn(log: "ContextGuardPlugin: Detected a custom value for the SDK-managed context key \"\(key.rawValue)\"; overriding SDK-managed context keys is deprecated and will be unsupported in a future major version.")
        }
    }

    /**
     Compares two context values by canonical JSON, so representation changes from a
     customer plugin rebuilding the context (Swift number or bool types vs `NSNumber`)
     never register as overrides. Values that cannot be encoded compare as equal —
     the fail-safe direction for a detection-only warning.
     */
    private func isSameValue(_ lhs: AnyCodable?, _ rhs: AnyCodable?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            guard let left = canonicalJson(of: lhs), let right = canonicalJson(of: rhs) else { return true }
            return left == right
        default:
            return false
        }
    }

    private func canonicalJson(of value: AnyCodable) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return (try? encoder.encode(value)).flatMap { String(data: $0, encoding: .utf8) }
    }
}
