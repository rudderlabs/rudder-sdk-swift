//
//  RudderUITestsLaunchTests.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

/**
 * RudderUITestsLaunchTests is a basic UI test class focused on verifying the application's
 * ability to launch successfully across different configurations.
 *
 * It serves as a smoke test that performs a standard launch sequence and captures a
 * screenshot of the initial UI state. This ensures the app environment is stable before
 * more complex end-to-end scenarios are executed.
 */
final class RudderUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
