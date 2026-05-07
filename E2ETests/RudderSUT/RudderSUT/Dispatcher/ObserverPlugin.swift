//
//  ObserverPlugin.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import RudderStackAnalytics

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
