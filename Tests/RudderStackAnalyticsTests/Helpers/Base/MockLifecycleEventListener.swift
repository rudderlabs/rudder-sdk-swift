//
//  MockLifecycleEventListener.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 10/01/26.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - MockLifecycleEventListener

final class MockLifecycleEventListener: LifecycleEventListener {
    private(set) var onBackgroundCalled = false
    private(set) var onForegroundCalled = false
    private(set) var onTerminateCalled = false
    private(set) var onBecomeActiveCalled = false

    func onBackground() { onBackgroundCalled = true }
    func onForeground() { onForegroundCalled = true }
    func onTerminate() { onTerminateCalled = true }
    func onBecomeActive() { onBecomeActiveCalled = true }

    func reset() {
        onBackgroundCalled = false
        onForegroundCalled = false
        onTerminateCalled = false
        onBecomeActiveCalled = false
    }
}

// MARK: - Test Utilities

struct WaitTimeoutError: Error {}

/// Posts a notification and waits for the condition to become true.
/// Repeatedly posts the notification until the condition is met or timeout occurs.
@MainActor
func postAndWaitUntil(
    notification: Notification.Name,
    timeout: TimeInterval = 1.0,
    condition: @escaping () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else {
            throw WaitTimeoutError()
        }
        NotificationCenter.default.post(name: notification, object: nil)
        await Task.yield()
    }
}
