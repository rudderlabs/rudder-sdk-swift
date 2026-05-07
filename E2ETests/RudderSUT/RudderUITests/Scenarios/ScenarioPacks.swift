//
//  ScenarioPacks.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

enum ScenarioPacks {

    // Call once before starting MCPServer or running MCP-driven tests.
    static func registerAll() {
        SmokePack.register()
        PersistencePack.register()
    }
}
