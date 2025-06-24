//
//  LifecycleObserverTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/03/25.
//

import Foundation
import XCTest
@testable import RudderStackAnalytics

final class LifecycleObserverTests: XCTestCase {
    private var observer: LifecycleObserver!
    private var mockListener: LifecycleEventListenerMock!

    override func setUp() {
        super.setUp()
        observer = LifecycleObserver(analytics: MockProvider.clientWithMemoryStorage)
        mockListener = LifecycleEventListenerMock()
    }

    override func tearDown() {
        observer = nil
        mockListener = nil
        super.tearDown()
    }

    func test_setup_registersNotifications() {
            given("A LifecycleTrackingPlugin instance is set up") {
                let notificationCenter = NotificationCenter.default

                when("setup is called") {
                    observer.addObserver(mockListener)
                    
                    then("Observers should be notified after setup") {
                        AppLifecycleEvent.allCases.forEach { event in
                            notificationCenter.post(name: event.notificationName, object: nil)
                        }
                        XCTAssertTrue(mockListener.onBackgroundCalled && mockListener.onTerminateCalled && mockListener.onForegroundCalled && mockListener.onBecomeActiveCalled)
                    }
                }
            }
        }

        func test_addObserver_observerIsNotifiedOnEvents() {
            given("An observer is added to the plugin") {
                observer.addObserver(mockListener)

                when("registerNotifications is called and a background event occurs") {
                    observer.registerNotifications()
                    NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)

                    then("Observer should have received background event notification") {
                        XCTAssertTrue(mockListener.onBackgroundCalled)
                    }
                }
            }
        }

        func test_removeObserver_observerIsNotNotified() {
            given("An observer is added and then removed from the plugin") {
                observer.addObserver(mockListener)
                observer.removeObserver(mockListener)

                when("A background event occurs") {
                    NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)

                    then("Observer should not be notified after removal") {
                        XCTAssertFalse(mockListener.onBackgroundCalled)
                    }
                }
            }
        }

        func test_pluginDeinit_removesNotificationObservers() {
            given("A plugin instance with registered notifications") {
                observer.registerNotifications()

                when("The plugin instance is deinitialized") {
                    observer = nil

                    then("No crashes should occur when posting notifications") {
                        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
                        NotificationCenter.default.post(name: AppLifecycleEvent.terminate.notificationName, object: nil)
                    }
                }
            }
        }
}

// MARK: - Mocks

final class LifecycleEventListenerMock: LifecycleEventListener {
    var onBackgroundCalled = false
    var onTerminateCalled = false
    var onForegroundCalled = false
    var onBecomeActiveCalled = false

    func onBackground() { onBackgroundCalled = true }
    func onTerminate() { onTerminateCalled = true }
    func onForeground() { onForegroundCalled = true }
    func onBecomeActive() { onBecomeActiveCalled = true }
}
