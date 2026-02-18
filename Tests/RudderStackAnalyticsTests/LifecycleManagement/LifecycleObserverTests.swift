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
    
    @Test("when background event occurs, then observer should receive onBackground callback")
    func testBackgroundEventCallsObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        observer.simulateEvent(.background)
        
        #expect(mockListener.onBackgroundCalled)
    }
    
    @Test("when foreground event occurs, then observer should receive onForeground callback")
    func testForegroundEventCallsObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        observer.simulateEvent(.foreground)
        
        #expect(mockListener.onForegroundCalled)
    }
    
    @Test("when terminate event occurs, then observer should receive onTerminate callback")
    func testTerminateEventCallsObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        observer.simulateEvent(.terminate)
        
        #expect(mockListener.onTerminateCalled)
    }
    
    @Test("when becomeActive event occurs, then observer should receive onBecomeActive callback")
    func testBecomeActiveEventCallsObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        observer.simulateEvent(.becomeActive)
        
        #expect(mockListener.onBecomeActiveCalled)
    }
    
    // MARK: - Multiple Observers Tests
    
    @Test("when background event occurs, then all observers should receive callback")
    func testMultipleObserversReceiveBackgroundEvent() {
        let observer = MockLifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        observer.addObserver(mockListener1)
        observer.addObserver(mockListener2)
        observer.simulateEvent(.background)
        
        #expect(mockListener1.onBackgroundCalled)
        #expect(mockListener2.onBackgroundCalled)
    }
    
    @Test("when foreground event occurs, then all observers should receive callback")
    func testMultipleObserversReceiveForegroundEvent() {
        let observer = MockLifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        observer.addObserver(mockListener1)
        observer.addObserver(mockListener2)
        observer.simulateEvent(.foreground)
        
        #expect(mockListener1.onForegroundCalled)
        #expect(mockListener2.onForegroundCalled)
    }
    
    // MARK: - Removed Observer Tests
    
    @Test("when observer is removed, then it should not receive events")
    func testRemovedObserverDoesNotReceiveEvent() {
        let observer = MockLifecycleObserver()
        let mockListener1 = MockLifecycleEventListener()
        let mockListener2 = MockLifecycleEventListener()
        
        observer.addObserver(mockListener1)
        observer.addObserver(mockListener2)
        observer.removeObserver(mockListener1)
        observer.simulateEvent(.background)
        
        #expect(!mockListener1.onBackgroundCalled)
        #expect(mockListener2.onBackgroundCalled)
    }
    
    // MARK: - Sequential Event Tests
    
    @Test("when multiple different events occur, then observer should receive all callbacks")
    func testSequentialEventsCallObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        
        observer.simulateEvent(.background)
        #expect(mockListener.onBackgroundCalled)
        
        observer.simulateEvent(.foreground)
        #expect(mockListener.onForegroundCalled)
    }
    
    // MARK: - All Lifecycle Events Test
    
    @Test("when all lifecycle events occur, then observer should receive all callbacks")
    func testAllLifecycleEventsCallObserver() {
        let observer = MockLifecycleObserver()
        let mockListener = MockLifecycleEventListener()
        
        observer.addObserver(mockListener)
        
        observer.simulateEvent(.background)
        observer.simulateEvent(.foreground)
        observer.simulateEvent(.terminate)
        observer.simulateEvent(.becomeActive)
        
        #expect(mockListener.onBackgroundCalled)
        #expect(mockListener.onForegroundCalled)
        #expect(mockListener.onTerminateCalled)
        #expect(mockListener.onBecomeActiveCalled)
    }
}
