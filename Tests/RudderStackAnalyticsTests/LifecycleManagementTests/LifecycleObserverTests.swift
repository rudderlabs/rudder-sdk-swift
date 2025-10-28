//
//  LifecycleObserverTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/03/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("LifecycleObserver Tests")
class LifecycleObserverTests {
    
    var mockAnalytics: Analytics
    var mockListener: MockLifecycleEventListener
    var lifecycleObserver: LifecycleObserver?
    
    init() {
        mockAnalytics = SwiftTestMockProvider.createMockAnalytics()
        mockListener = MockLifecycleEventListener()
        lifecycleObserver = LifecycleObserver(analytics: mockAnalytics)
    }
    
    @Test("when lifecycle events are posted, then the correct callbacks are triggered", arguments: [
        (AppLifecycleEvent.background,  \MockLifecycleEventListener.onBackgroundCalled),
        (AppLifecycleEvent.foreground,  \MockLifecycleEventListener.onForegroundCalled),
        (AppLifecycleEvent.terminate,   \MockLifecycleEventListener.onTerminateCalled),
        (AppLifecycleEvent.becomeActive, \MockLifecycleEventListener.onBecomeActiveCalled)
    ])
    func testLifecycleEventHandling(_ event: AppLifecycleEvent,
                                    _ expectedFlag: KeyPath<MockLifecycleEventListener, Bool>) {
        lifecycleObserver?.addObserver(mockListener)
        NotificationCenter.default.post(name: event.notificationName, object: nil)
        
        #expect(mockListener[keyPath: expectedFlag] == true, "Expected correct callback for \(event)")
        
        let allFlags: [KeyPath<MockLifecycleEventListener, Bool>] = [
            \.onBackgroundCalled,
            \.onForegroundCalled,
            \.onTerminateCalled,
            \.onBecomeActiveCalled
        ]
        
        for flag in allFlags where flag != expectedFlag {
            #expect(mockListener[keyPath: flag] == false, "Expected \(flag) to remain false for \(event)")
        }
    }
    
    @Test("when multiple observers are registered, then all should receive lifecycle event callbacks")
    func testMultipleObservers() {
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        lifecycleObserver?.addObserver(mockListener1)
        lifecycleObserver?.addObserver(mockListener2)
        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
        
        #expect(mockListener1.onBackgroundCalled == true)
        #expect(mockListener2.onBackgroundCalled == true)
    }
    
    @Test("when sequential lifecycle events are posted, then they should be handled correctly")
    func testSequentialEventHandling() {
        lifecycleObserver?.addObserver(mockListener)
        NotificationCenter.default.post(name: AppLifecycleEvent.foreground.notificationName, object: nil)
        NotificationCenter.default.post(name: AppLifecycleEvent.becomeActive.notificationName, object: nil)
        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
        
        #expect(mockListener.onForegroundCalled == true)
        #expect(mockListener.onBecomeActiveCalled == true)
        #expect(mockListener.onBackgroundCalled == true)
    }
    
    @Test("when observer removal during event processing is attempted, it should work correctly")
    func testObserverRemovalDuringEventProcessing() {
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        lifecycleObserver?.addObserver(mockListener1)
        lifecycleObserver?.addObserver(mockListener2)
        
        lifecycleObserver?.removeObserver(mockListener1)
        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
        
        #expect(mockListener1.onBackgroundCalled == false)
        #expect(mockListener2.onBackgroundCalled == true)
    }
}

// MARK: - MockLifecycleEventListener

final class MockLifecycleEventListener: LifecycleEventListener {
    var onBackgroundCalled = false
    var onForegroundCalled = false
    var onTerminateCalled = false
    var onBecomeActiveCalled = false
    
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
