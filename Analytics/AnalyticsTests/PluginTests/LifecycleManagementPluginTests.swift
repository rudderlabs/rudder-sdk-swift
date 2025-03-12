//
//  LifecycleManagementPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 11/03/25.
//

import UIKit
import XCTest
@testable import Analytics

final class LifecycleManagementPluginTests: XCTestCase {
    private var plugin: LifecycleTrackingPlugin!
    private var mockAnalyticsClient: AnalyticsClient!
    private var mockObserver: LifecycleEventObserverMock!

    override func setUp() {
        super.setUp()
        plugin = LifecycleTrackingPlugin()
        mockAnalyticsClient = MockProvider.clientWithMemoryStorage
        mockObserver = LifecycleEventObserverMock()
    }

    override func tearDown() {
        plugin = nil
        mockAnalyticsClient = nil
        mockObserver = nil
        super.tearDown()
    }

    func test_setup_registersNotifications() {
            given("A LifecycleTrackingPlugin instance is set up") {
                let notificationCenter = NotificationCenter.default

                when("setup is called") {
                    plugin.setup(analytics: mockAnalyticsClient)
                    plugin.addObserver(mockObserver)
                    
                    then("Observers should be notified after setup") {
                        AppLifecycleEvent.allCases.forEach { event in
                            notificationCenter.post(name: event.notificationName, object: nil)
                        }
                        XCTAssertTrue(mockObserver.onBackgroundCalled || mockObserver.onTerminateCalled || mockObserver.onForegroundCalled)
                    }
                }
            }
        }

        func test_addObserver_observerIsNotifiedOnEvents() {
            given("An observer is added to the plugin") {
                plugin.addObserver(mockObserver)

                when("registerNotifications is called and a background event occurs") {
                    plugin.registerNotifications()
                    NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)

                    then("Observer should have received background event notification") {
                        XCTAssertTrue(mockObserver.onBackgroundCalled)
                    }
                }
            }
        }

        func test_removeObserver_observerIsNotNotified() {
            given("An observer is added and then removed from the plugin") {
                plugin.addObserver(mockObserver)
                plugin.removeObserver(mockObserver)

                when("A background event occurs") {
                    NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)

                    then("Observer should not be notified after removal") {
                        XCTAssertFalse(mockObserver.onBackgroundCalled)
                    }
                }
            }
        }

        func test_pluginDeinit_removesNotificationObservers() {
            given("A plugin instance with registered notifications") {
                plugin.registerNotifications()

                when("The plugin instance is deinitialized") {
                    plugin = nil

                    then("No crashes should occur when posting notifications") {
                        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
                        NotificationCenter.default.post(name: AppLifecycleEvent.terminate.notificationName, object: nil)
                    }
                }
            }
        }
}

// MARK: - Mocks

final class LifecycleEventObserverMock: LifecycleEventListener {
    var onBackgroundCalled = false
    var onTerminateCalled = false
    var onForegroundCalled = false

    func onBackground() { onBackgroundCalled = true }
    func onTerminate() { onTerminateCalled = true }
    func onForeground() { onForegroundCalled = true }
}
