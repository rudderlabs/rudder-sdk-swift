//
//  MockLifecycleEventListener.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 10/01/26.
//

import Foundation
@testable import RudderStackAnalytics

// MARK: - MockLifecycleEventListener

final class MockLifecycleEventListener: LifecycleEventListener {
    private(set) var onBackgroundCallCount = 0
    private(set) var onForegroundCallCount = 0
    private(set) var onTerminateCallCount = 0
    
    func onBackground() { onBackgroundCallCount += 1 }
    func onForeground() { onForegroundCallCount += 1 }
    func onTerminate() { onTerminateCallCount += 1 }
}

// MARK: - Lifecycle Simulation

extension Analytics {
    /**
     Delivers a lifecycle event to this instance only.
     
     A real notification on `NotificationCenter.default` reaches every `Analytics` instance alive in the
     process, including the ones other test suites created.
     */
    func simulateLifecycleEvent(_ event: AppLifecycleEvent) {
        self.lifecycleObserver?.handle(event)
    }
}
