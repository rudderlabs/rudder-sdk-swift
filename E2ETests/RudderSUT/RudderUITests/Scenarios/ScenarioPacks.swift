//
//  ScenarioPacks.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

/**
 * ScenarioPacks acts as a centralized registry hub for all test scenario packs.
 *
 * It provides a single entry point (`registerAll`) to initialize and register
 * all available test sequences into the global PackRegistry. This ensures
 * that all pre-defined scenarios are loaded and available for execution by
 * the MCPServer or the internal test runner.
 */
enum ScenarioPacks {

    // Call once before starting MCPServer or running MCP-driven tests.
    static func registerAll() {
        SmokePack.register()
        PersistencePack.register()
    }
}
