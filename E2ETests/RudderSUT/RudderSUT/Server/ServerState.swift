//
//  ServerState.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Combine

class ServerState: ObservableObject {
    @Published var port: UInt16?
    static let shared = ServerState()
    private init() {}
}
