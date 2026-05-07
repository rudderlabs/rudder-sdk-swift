//
//  ObserverPlugin.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation
import RudderStackAnalytics

/**
 * ObserverPlugin is a specialized SDK plugin designed for test observability.
 * It intercepts all analytics events (Track, Identify, etc.) as they are processed by the SDK.
 *
 * Instead of modifying the events, it serializes them and pushes them to an SSE stream,
 * allowing external test tools to verify in real-time what events the SDK is generating
 * and what their contents are.
 */
class ObserverPlugin: Plugin {

    // MARK: - Properties

    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    let sseStream: SSEStream

    // MARK: - Init

    init(stream: SSEStream) {
        self.sseStream = stream
    }
}

// MARK: - Plugin Execution

extension ObserverPlugin {

    func intercept(event: any Event) -> (any Event)? {
        if let payload = try? JSONEncoder().encode(event),
           let dict = try? JSONSerialization.jsonObject(with: payload) as? [String: Any] {
            sseStream.push(type: "sdk_event", payload: [
                "eventType": event.type.rawValue,
                "event":     dict
            ])
        }
        return event
    }
}
