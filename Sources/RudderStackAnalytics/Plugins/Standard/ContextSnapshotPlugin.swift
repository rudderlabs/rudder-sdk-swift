//
//  ContextSnapshotPlugin.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/26.
//

import Foundation

// MARK: - ContextSnapshotPlugin
/**
 A plugin that records the SDK-stamped base context values before any customer plugin runs.

 Registered last among the built-in `preProcess` plugins. The terminal guard compares the delivered values against this snapshot to detect customer-plugin overrides. The pipeline processes one event at a time, so a single slot suffices; the message id check makes a stale slot fail safe (no warning) rather than misreport.
 */

final class ContextSnapshotPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    @Synchronized private var snapshot: Snapshot?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        var values = [String: AnyCodable]()
        
        SDKManagedContextKey.baseKeys.forEach { key in
            values[key.rawValue] = event.context?[key.rawValue]
        }
        
        self.snapshot = Snapshot(messageId: event.messageId, values: values)
        return event
    }
    
    func consumeSnapshot(for messageId: String) -> [String: AnyCodable]? {
        guard let snapshot, snapshot.messageId == messageId else { return nil }
        self.snapshot = nil
        return snapshot.values
    }
}

/**
 The recorded base-key values for a single event.
 */
private struct Snapshot {
    let messageId: String
    let values: [String: AnyCodable]
}
