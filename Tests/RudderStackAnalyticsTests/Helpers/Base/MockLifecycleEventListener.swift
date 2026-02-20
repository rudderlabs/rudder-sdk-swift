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

// MARK: - MockLifecycleObserver

/**
 A test-safe lifecycle observer that mirrors the real `LifecycleObserver`'s
 add/remove/notify contract but uses direct method invocation instead of
 `NotificationCenter.default`.
 
 **Why this exists:** The real `LifecycleObserver` registers for real system
 notifications (e.g. `NSApplication.didBecomeActiveNotification`) on
 `NotificationCenter.default`. When tests post these notifications, ALL
 `LifecycleObserver` instances in the process receive them — including those
 from lingering `Analytics` instances created by other test suites. Those
 instances may be mid-deallocation, causing SIGABRT/SIGSEGV when their
 handlers access a destroyed `pthread_rwlock_t`.
 */
final class MockLifecycleObserver {
    private var observers: [WeakObserver] = []
    
    func addObserver(_ observer: LifecycleEventListener) {
        observers.append(WeakObserver(observer))
    }
    
    func removeObserver(_ observer: LifecycleEventListener) {
        observers.removeAll { $0.observer === observer }
    }
    
    func simulateEvent(_ event: AppLifecycleEvent) {
        observers.removeAll { $0.observer == nil }
        let active = observers.compactMap { $0.observer }
        
        switch event {
        case .background: active.forEach { $0.onBackground() }
        case .terminate: active.forEach { $0.onTerminate() }
        case .foreground: active.forEach { $0.onForeground() }
        case .becomeActive: active.forEach { $0.onBecomeActive() }
        }
    }
}
