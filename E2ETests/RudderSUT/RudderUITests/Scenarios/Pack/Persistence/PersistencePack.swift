//
//  PersistencePack.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

class PersistencePack: ScenarioTestCase {

    // MARK: - Registration

    static func register() {
        PackRegistry.shared.register(
            name: "persistence.offline_queue_replay",
            steps: [
                .networkOffline,
                .track(name: "Offline Event 1"),
                .track(name: "Offline Event 2"),
                .networkOnline,
                .waitForBatch(timeout: 10)
            ]
        )
        PackRegistry.shared.register(
            name: "persistence.kill_and_relaunch",
            steps: [
                .track(name: "Before Kill"),
                .kill,
                .coldStart,
                .waitForBatch(timeout: 5)
            ]
        )
    }
}

// MARK: - Tests

extension PersistencePack {

    func test_offline_queue_replay() {
        rudderScenario { ctx in
            try ctx.networkOffline()
            try ctx.track("Offline Event 1")
            try ctx.track("Offline Event 2")
            try ctx.networkOnline()
            try ctx.waitForBatch(timeout: 10)

            let events = ctx.mockServer.lastBatch()?["batch"] as? [[String: Any]] ?? []
            let names  = events.compactMap { $0["event"] as? String }
            XCTAssertTrue(names.contains("Offline Event 1"))
            XCTAssertTrue(names.contains("Offline Event 2"))
        }
    }

    func test_kill_and_relaunch_delivers_queued_events() {
        rudderScenario { ctx in
            try ctx.track("Before Kill")
            try ctx.kill()
            try ctx.coldStart()
            try ctx.waitForBatch(timeout: 5)
        }
    }
}
