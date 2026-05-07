//
//  SmokePack.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * SmokePack contains a set of basic "smoke tests" designed to verify that the
 * SDK's core event types, payload fidelity, and state management are operational.
 *
 * It registers key sequences in the PackRegistry for MCP-driven reuse and provides
 * standard XCTest methods to execute them as part of the CI/CD pipeline.
 * These tests act as an early warning system for major regressions.
 */
class SmokePack: ScenarioTestCase {

    // MARK: - Registration

    static func register() {
        PackRegistry.shared.register(
            name: "smoke.basic_track",
            steps: [
                .track(name: "Smoke Test Event"),
                .waitForBatch(timeout: 5)
            ]
        )
        PackRegistry.shared.register(
            name: "smoke.basic_identify",
            steps: [
                .identify(userId: "smoke_user"),
                .waitForBatch(timeout: 5)
            ]
        )
        PackRegistry.shared.register(
            name: "smoke.basic_screen",
            steps: [
                .screen(name: "Home Screen"),
                .waitForBatch(timeout: 5)
            ]
        )
        PackRegistry.shared.register(
            name: "smoke.basic_group",
            steps: [
                .group(groupId: "team_42"),
                .waitForBatch(timeout: 5)
            ]
        )
        PackRegistry.shared.register(
            name: "smoke.basic_alias",
            steps: [
                .alias(newId: "new_user_456"),
                .waitForBatch(timeout: 5)
            ]
        )
    }
}

// MARK: - Core Event Type Tests

extension SmokePack {

    func test_basic_track() {
        rudderScenario { ctx in
            try ctx.track("Smoke Test Event")
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(named: "Smoke Test Event")
            else { XCTFail("Smoke Test Event not found in batch"); return }

            XCTAssertEqual(event["type"] as? String, "track")
        }
    }

    func test_basic_identify() {
        rudderScenario { ctx in
            try ctx.identify("smoke_user")
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(ofType: "identify")
            else { XCTFail("Identify event not found in batch"); return }

            XCTAssertEqual(event["userId"] as? String, "smoke_user")
        }
    }

    func test_screen() {
        rudderScenario { ctx in
            try ctx.screen("Home Screen", category: "Main")
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(ofType: "screen")
            else { XCTFail("Screen event not found in batch"); return }

            XCTAssertEqual(event["event"] as? String, "Home Screen")
            let props = event["properties"] as? [String: Any]
            XCTAssertEqual(props?["name"] as? String, "Home Screen")
            XCTAssertEqual(props?["category"] as? String, "Main")
        }
    }

    func test_group() {
        rudderScenario { ctx in
            try ctx.group("team_42", traits: ["plan": "enterprise"])
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(ofType: "group")
            else { XCTFail("Group event not found in batch"); return }

            XCTAssertEqual(event["groupId"] as? String, "team_42")
            let traits = event["traits"] as? [String: Any]
            XCTAssertEqual(traits?["plan"] as? String, "enterprise")
        }
    }

    func test_alias() {
        rudderScenario { ctx in
            try ctx.alias("new_user_456", previousId: "anon_old")
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(ofType: "alias")
            else { XCTFail("Alias event not found in batch"); return }

            XCTAssertEqual(event["userId"] as? String, "new_user_456")
            XCTAssertEqual(event["previousId"] as? String, "anon_old")
        }
    }
}

// MARK: - Payload Fidelity Tests

extension SmokePack {

    func test_track_delivers_properties() {
        rudderScenario { ctx in
            try ctx.track("Purchase", properties: ["item": "widget", "quantity": 3])
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(named: "Purchase")
            else { XCTFail("Purchase event not found in batch"); return }

            let props = event["properties"] as? [String: Any]
            XCTAssertEqual(props?["item"] as? String, "widget")
            XCTAssertEqual(props?["quantity"] as? Int, 3)
        }
    }

    func test_identify_delivers_traits() {
        rudderScenario { ctx in
            try ctx.identify("user_789", traits: ["name": "Alice", "plan": "pro"])
            try ctx.waitForBatch(timeout: 5)

            guard let event = ctx.lastEvent(ofType: "identify")
            else { XCTFail("Identify event not found in batch"); return }

            XCTAssertEqual(event["userId"] as? String, "user_789")
            print("event :: \(event)")
            guard let context = event["context"] as? [String: Any], let traits = context["traits"] as? [String: Any]
                    else { XCTFail("Traits not found in event"); return }
            XCTAssertEqual(traits["name"] as? String, "Alice")
            XCTAssertEqual(traits["plan"] as? String, "pro")
        }
    }
}

// MARK: - State Tests

extension SmokePack {

    func test_anonymous_id_is_set() {
        rudderScenario { ctx in
            let anonId = try ctx.readState("anonymousId")
            XCTAssertFalse(anonId.isEmpty, "SDK must assign an anonymousId on init")
        }
    }

    func test_user_id_after_identify() {
        rudderScenario { ctx in
            try ctx.identify("test_user_99")
            try ctx.waitForBatch(timeout: 5)
            try ctx.assertState("userId", equals: "test_user_99")
        }
    }

    func test_reset_clears_user_id() {
        rudderScenario { ctx in
            try ctx.identify("user_to_clear")
            try ctx.waitForBatch(timeout: 5)
            try ctx.reset()
            let userId = try ctx.readState("userId")
            XCTAssertTrue(userId.isEmpty, "userId should be cleared after reset")
        }
    }
}
