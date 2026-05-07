//
//  PersistencePack.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * PersistencePack verifies that the SDK reliably persists and delivers events
 * across different conditions — background transitions, identity changes, and resets.
 */
class PersistencePack: ScenarioTestCase {

    // MARK: - Registration

    static func register() {
        PackRegistry.shared.register(
            name: "persistence.flush_on_background",
            steps: [
                .track(name: "Background Flush Event"),
                .background,
                .waitForBatch(timeout: 5)
            ]
        )
        PackRegistry.shared.register(
            name: "persistence.user_id_in_events",
            steps: [
                .identify(userId: "persistent_user"),
                .track(name: "Post-Identify Event"),
                .background,
                .waitForBatch(timeout: 5)
            ]
        )
    }
}

// MARK: - Tests

extension PersistencePack {

    func test_flush_on_background() {
        rudderScenario { ctx in
            try ctx.track("Background Flush Event")
            try ctx.background()
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(named: "Background Flush Event")
            else { XCTFail("Event not found after background flush"); return }

            XCTAssertEqual(event["type"] as? String, "track")
        }
    }

    func test_anonymous_id_matches_state() {
        rudderScenario { ctx in
            let stateAnonId = try ctx.readState("anonymousId")
            XCTAssertFalse(stateAnonId.isEmpty)

            try ctx.track("AnonId Check")
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(named: "AnonId Check")
            else { XCTFail("Event not found in batch"); return }

            XCTAssertEqual(event["anonymousId"] as? String, stateAnonId,
                           "anonymousId in event must match SDK state")
        }
    }

    func test_reset_generates_new_anonymous_id() {
        rudderScenario { ctx in
            let originalId = try ctx.readState("anonymousId")
            XCTAssertFalse(originalId.isEmpty)

            try ctx.reset()

            let newId = try ctx.readState("anonymousId")
            XCTAssertFalse(newId.isEmpty)
            XCTAssertNotEqual(originalId, newId, "Reset should generate a new anonymousId")
        }
    }
}
