//
//  LifecycleObserverTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/03/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - LifecycleObserver Tests

@Suite("LifecycleObserver Tests")
struct LifecycleObserverTests {
    
    @Test("when background notification is posted, then observer should receive onBackground callback")
    func testBackgroundNotificationCallsObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.background.notificationName) {
            mockListener.onBackgroundCalled
        }
        
        #expect(mockListener.onBackgroundCalled)
    }
    
    @Test("when foreground notification is posted, then observer should receive onForeground callback")
    func testForegroundNotificationCallsObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.foreground.notificationName) {
            mockListener.onForegroundCalled
        }
        
        #expect(mockListener.onForegroundCalled)
    }
    
    @Test("when terminate notification is posted, then observer should receive onTerminate callback")
    func testTerminateNotificationCallsObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.terminate.notificationName) {
            mockListener.onTerminateCalled
        }
        
        #expect(mockListener.onTerminateCalled)
    }
    
    @Test("when becomeActive notification is posted, then observer should receive onBecomeActive callback")
    func testBecomeActiveNotificationCallsObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.becomeActive.notificationName) {
            mockListener.onBecomeActiveCalled
        }
        
        #expect(mockListener.onBecomeActiveCalled)
    }
    
    // MARK: - Multiple Observers Tests
    
    @Test("when background notification is posted, then all observers should receive callback")
    func testMultipleObserversReceiveBackgroundNotification() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener1)
        lifecycleObserver.addObserver(mockListener2)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.background.notificationName) {
            mockListener1.onBackgroundCalled && mockListener2.onBackgroundCalled
        }
        
        #expect(mockListener1.onBackgroundCalled)
        #expect(mockListener2.onBackgroundCalled)
    }
    
    @Test("when foreground notification is posted, then all observers should receive callback")
    func testMultipleObserversReceiveForegroundNotification() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener1)
        lifecycleObserver.addObserver(mockListener2)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.foreground.notificationName) {
            mockListener1.onForegroundCalled && mockListener2.onForegroundCalled
        }
        
        #expect(mockListener1.onForegroundCalled)
        #expect(mockListener2.onForegroundCalled)
    }
    
    // MARK: - Removed Observer Tests
    
    @Test("when observer is removed, then it should not receive notifications")
    func testRemovedObserverDoesNotReceiveNotification() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener1)
        lifecycleObserver.addObserver(mockListener2)
        lifecycleObserver.removeObserver(mockListener1)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.background.notificationName) {
            mockListener2.onBackgroundCalled
        }
        
        #expect(!mockListener1.onBackgroundCalled)
        #expect(mockListener2.onBackgroundCalled)
    }
    
    // MARK: - Sequential Notification Tests
    
    @Test("when multiple different notifications are posted, then observer should receive all callbacks")
    func testSequentialNotificationsCallObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.background.notificationName) {
            mockListener.onBackgroundCalled
        }
        
        #expect(mockListener.onBackgroundCalled)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.foreground.notificationName) {
            mockListener.onForegroundCalled
        }
        
        #expect(mockListener.onForegroundCalled)
    }
    
    // MARK: - All Lifecycle Events Test
    
    @Test("when all lifecycle notifications are posted, then observer should receive all callbacks")
    func testAllLifecycleEventsCallObserver() async throws {
        let lifecycleObserver = LifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        lifecycleObserver.addObserver(mockListener)
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.background.notificationName) {
            mockListener.onBackgroundCalled
        }
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.foreground.notificationName) {
            mockListener.onForegroundCalled
        }
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.terminate.notificationName) {
            mockListener.onTerminateCalled
        }
        
        try await postAndWaitUntil(notification: AppLifecycleEvent.becomeActive.notificationName) {
            mockListener.onBecomeActiveCalled
        }
        
        #expect(mockListener.onBackgroundCalled)
        #expect(mockListener.onForegroundCalled)
        #expect(mockListener.onTerminateCalled)
        #expect(mockListener.onBecomeActiveCalled)
    }
}
