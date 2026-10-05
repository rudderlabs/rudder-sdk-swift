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
    private let observer = LifecycleObserver()
    private let listener = MockLifecycleEventListener()
    
    // MARK: - Foreground State Tests
    
    @Test("given a new observer, when no lifecycle event occurred, then the app counts as in the background")
    func testStartsInBackground() {
        #expect(!observer.isInForeground)
    }
    
    @Test("given an app in the background, when a foreground signal arrives, then the listener receives onForeground", arguments: [
        AppLifecycleEvent.foreground, .becomeActive
    ])
    func testForegroundSignalCallsListener(signal: AppLifecycleEvent) {
        observer.addObserver(listener)
        
        observer.handle(signal)
        
        #expect(observer.isInForeground)
        #expect(listener.onForegroundCallCount == 1)
    }
    
    @Test("given an app that returns from the background, when both foreground signals arrive, then the listener receives onForeground once")
    func testBothForegroundSignalsCallListenerOnce() {
        observer.addObserver(listener)
        
        observer.handle(.foreground)
        observer.handle(.becomeActive)
        
        #expect(listener.onForegroundCallCount == 1)
    }
    
    @Test("given an app in the foreground, when it becomes active again without a background, then the listener receives no second onForeground")
    func testBecomeActiveAfterInterruptionDoesNotCallListener() {
        observer.addObserver(listener)
        observer.handle(.becomeActive)
        
        observer.handle(.becomeActive)
        
        #expect(listener.onForegroundCallCount == 1)
    }
    
    @Test("given an app in the foreground, when it moves to the background, then the listener receives onBackground once")
    func testBackgroundEventCallsListenerOnce() {
        observer.addObserver(listener)
        observer.handle(.foreground)
        
        observer.handle(.background)
        observer.handle(.background)
        
        #expect(!observer.isInForeground)
        #expect(listener.onBackgroundCallCount == 1)
    }
    
    @Test("given an app that started in the background, when a background event arrives, then the listener receives no onBackground")
    func testBackgroundEventWithoutForegroundDoesNotCallListener() {
        observer.addObserver(listener)
        
        observer.handle(.background)
        
        #expect(listener.onBackgroundCallCount == 0)
    }
    
    @Test("given an app that moved to the background, when it returns to the foreground, then the listener receives onForeground again")
    func testReturnToForegroundCallsListenerAgain() {
        observer.addObserver(listener)
        observer.handle(.becomeActive)
        observer.handle(.background)
        
        observer.handle(.foreground)
        observer.handle(.becomeActive)
        
        #expect(listener.onForegroundCallCount == 2)
    }
    
    @Test("when terminate event occurs, then the listener receives onTerminate and the foreground state is unchanged", arguments: [true, false])
    func testTerminateEventCallsListener(isInForeground: Bool) {
        observer.addObserver(listener)
        if isInForeground {
            observer.handle(.foreground)
        }
        
        observer.handle(.terminate)
        
        #expect(listener.onTerminateCallCount == 1)
        #expect(observer.isInForeground == isInForeground)
    }
    
    // MARK: - Observer Management Tests
    
    @Test("given an app in the foreground, when a listener is added, then it receives onForeground at once")
    func testListenerAddedInForegroundReceivesOnForeground() {
        observer.handle(.becomeActive)
        
        observer.addObserver(listener)
        
        #expect(listener.onForegroundCallCount == 1)
    }
    
    @Test("given an app in the background, when a listener is added, then it receives no callback")
    func testListenerAddedInBackgroundReceivesNoCallback() {
        observer.addObserver(listener)
        
        #expect(listener.onForegroundCallCount == 0)
        #expect(listener.onBackgroundCallCount == 0)
    }
    
    @Test("when a lifecycle change occurs, then all listeners receive the callback")
    func testMultipleListenersReceiveEvents() {
        let secondListener = MockLifecycleEventListener()
        observer.addObserver(listener)
        observer.addObserver(secondListener)
        
        observer.handle(.foreground)
        observer.handle(.background)
        
        #expect(listener.onForegroundCallCount == 1)
        #expect(secondListener.onForegroundCallCount == 1)
        #expect(listener.onBackgroundCallCount == 1)
        #expect(secondListener.onBackgroundCallCount == 1)
    }
    
    @Test("when a listener is removed, then it receives no more events")
    func testRemovedListenerDoesNotReceiveEvent() {
        let secondListener = MockLifecycleEventListener()
        observer.addObserver(listener)
        observer.addObserver(secondListener)
        
        observer.removeObserver(listener)
        observer.handle(.foreground)
        
        #expect(listener.onForegroundCallCount == 0)
        #expect(secondListener.onForegroundCallCount == 1)
    }
    
    @Test("when a listener is released, then the remaining listeners still receive events")
    func testReleasedListenerIsDropped() {
        var releasedListener: MockLifecycleEventListener? = MockLifecycleEventListener()
        if let releasedListener {
            observer.addObserver(releasedListener)
        }
        observer.addObserver(listener)
        
        releasedListener = nil
        observer.handle(.foreground)
        
        #expect(listener.onForegroundCallCount == 1)
    }
}
