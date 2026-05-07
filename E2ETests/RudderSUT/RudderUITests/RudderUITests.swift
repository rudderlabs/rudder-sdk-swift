//
//  RudderUITests.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

// MARK: - MCP Gateway

/// Run this test with MCP_GATEWAY=1 set in the scheme environment variables,
/// then open Claude Code in this repo directory. Claude discovers the rudder.*
/// tools via .mcp.json and drives the SDK via natural-language prompts.
final class MCPGatewayTest: ScenarioTestCase {

    func testMCPGateway() throws {
        guard ProcessInfo.processInfo.environment["MCP_GATEWAY"] == "1" else {
            throw XCTSkip("MCP gateway skipped. Set env var MCP_GATEWAY=1 in the scheme to enable.")
        }
        rudderScenario(initAnalytics: false) { [unowned self] _ in
            guard let interpreter = self.interpreter else { return }
            let mcp = MCPServer(interpreter: interpreter)
            mcp.start(port: 7777)
            print("[MCPGateway] Ready — connect Claude Code at http://127.0.0.1:7777")
            let timeout = ProcessInfo.processInfo.environment["MCP_GATEWAY_TIMEOUT"]
                .flatMap(TimeInterval.init) ?? 600
            Thread.sleep(forTimeInterval: timeout)
            mcp.stop()
        }
    }
}
