//
//  ServerState.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Combine

/**
 * ServerState is a shared data container that holds the dynamic state of the internal HTTP server.
 *
 * It uses the ObservableObject protocol to allow SwiftUI views to reactively update
 * when server properties (like the active port) change. This ensures the UI always
 * reflects the current connectivity status of the test server.
 */
class ServerState: ObservableObject {
    @Published var port: UInt16?
    static let shared = ServerState()
    private init() {}
}
