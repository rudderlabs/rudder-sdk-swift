//
//  SessionPersistenceTests.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * SessionPersistenceTests focuses on verifying that the SDK maintains consistent
 * session data and state across different application lifecycle events.
 *
 * This includes checking if identifiers like anonymousId persist through app restarts,
 * ensuring that events are flushed correctly when the app moves to the background,
 * and validating privacy-related behaviors like event suppression after a user opts out.
 */
class SessionPersistenceTests: ScenarioTestCase {

    func test_anonymousId_persistsAcrossColdStart() {
        rudderScenario { ctx in
            let firstId = try ctx.readState("anonymousId")
            XCTAssertFalse(firstId.isEmpty)

            try ctx.kill()
            try ctx.coldStart()
            Thread.sleep(forTimeInterval: 0.5)

            let secondId = try ctx.readState("anonymousId")
            XCTAssertEqual(firstId, secondId, "Anonymous ID should persist across a cold start")
        }
    }

    func test_track_eventDeliveredAfterBackground() {
        rudderScenario { ctx in
            try ctx.track("Button Tapped", properties: ["screen": "Home"])
            try ctx.background()
            try ctx.waitForBatch(timeout: 5)

            guard let batch  = ctx.mockServer.lastBatch(),
                  let events = batch["batch"] as? [[String: Any]],
                  let event  = events.first(where: { $0["event"] as? String == "Button Tapped" })
            else { XCTFail("Event not found in batch"); return }

            let props = event["properties"] as? [String: Any]
            XCTAssertEqual(props?["screen"] as? String, "Home")
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
