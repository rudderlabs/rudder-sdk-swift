//
//  SmokePack.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

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
    }
}

// MARK: - Tests

extension SmokePack {

    func test_basic_track() {
        rudderScenario { ctx in
            try ctx.track("Smoke Test Event")
            try ctx.waitForBatch(timeout: 5)
        }
    }

    func test_basic_identify() {
        rudderScenario { ctx in
            try ctx.identify("smoke_user")
            try ctx.waitForBatch(timeout: 5)
        }
    }
}
