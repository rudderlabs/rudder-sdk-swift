//
//  SSEStream.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation
import Network

/**
 * SSEStream manages a collection of active network connections to broadcast real-time updates
 * using Server-Sent Events (SSE).
 *
 * It provides a thread-safe way to manage connections and push JSON-formatted event payloads
 * to all connected clients. This is primarily used in the test environment to notify external
 * observers about internal SDK activities and state changes.
 */
class SSEStream {

    // MARK: - Properties

    private var connections: [NWConnection] = []
    private let lock = NSLock()
}

// MARK: - Connection Management

extension SSEStream {

    func addConnection(_ conn: NWConnection) {
        lock.lock()
        connections.append(conn)
        lock.unlock()
    }
}

// MARK: - Event Push

extension SSEStream {

    func push(type: String, payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8)
        else { return }

        let message = Data("event: \(type)\ndata: \(json)\n\n".utf8)

        lock.lock()
        connections = connections.filter { $0.state == .ready }
        for conn in connections {
            conn.send(content: message, completion: .idempotent)
        }
        lock.unlock()
    }
}
