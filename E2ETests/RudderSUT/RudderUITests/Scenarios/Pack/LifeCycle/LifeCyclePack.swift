//
//  SessionPack.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * LifeCyclePack verifies that the SDK behaves correctly across app lifecycle
 * transitions — cold starts, background/foreground, and opt-out.
 */
class LifeCyclePack: ScenarioTestCase {

    // MARK: - Registration

    static func register() {
        PackRegistry.shared.register(
            name: "lifecycle.anonymous_id_persists_cold_start",
            steps: [
                .kill,
                .coldStart,
                .assertState(key: "anonymousId", expected: "")
            ]
        )
        PackRegistry.shared.register(
            name: "lifecycle.no_events_after_opt_out",
            steps: [
                .identify(userId: "user_123", traits: ["optOut": true]),
                .track(name: "Should Not Arrive"),
                .assertNoEvent(name: "Should Not Arrive", window: 3)
            ]
        )
    }
}

// MARK: - Tests

extension LifeCyclePack {

    func test_anonymousId_persistsAcrossColdStart() {
        rudderScenario { ctx in
            let firstId = try ctx.readState("anonymousId")
            XCTAssertFalse(firstId.isEmpty)

            try ctx.kill()
            try ctx.coldStart()
            try ctx.initialize()

            let secondId = try ctx.readState("anonymousId")
            XCTAssertEqual(firstId, secondId, "Anonymous ID should persist across a cold start")
        }
    }

    func test_noEventsAfterOptOut() {
        rudderScenario { ctx in
            try ctx.identify("user_123", traits: ["optOut": true])
            try ctx.track("Should Not Arrive")
            try ctx.assertNoEvent("Should Not Arrive", window: 3)
        }
    }
}
