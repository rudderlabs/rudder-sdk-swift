//
//  SSEStream.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Network

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
