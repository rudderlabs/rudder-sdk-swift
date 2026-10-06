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
    
    @Test("given an observer created on the main thread, when no lifecycle event occurred, then the foreground state is known at once")
    func testForegroundStateIsKnownAtOnceOnTheMainThread() async {
        let foregroundState = await MainActor.run { LifecycleObserver().foregroundState }
        
        #expect(foregroundState == false)
    }
    
    @Test("when a lifecycle change occurs, then the foreground state is known", arguments: [
        (event: AppLifecycleEvent.foreground, expected: true),
        (event: AppLifecycleEvent.background, expected: false)
    ])
    func testLifecycleChangeMakesForegroundStateKnown(event: AppLifecycleEvent, expected: Bool) {
        observer.handle(event)
        
        #expect(observer.foregroundState == expected)
    }
    
    @Test("given a lifecycle change before the first read of the app state, when the read arrives, then it does not replace the newer state")
    func testInitialAppStateDoesNotReplaceALifecycleChange() {
        observer.addObserver(listener)
        observer.handle(.foreground)
        
        observer.applyInitialAppState(isInForeground: false)
        
        #expect(observer.isInForeground)
        #expect(listener.onBackgroundCallCount == 0)
    }
    
    // MARK: - Observer Management Tests
    
    @Test("given an app in the foreground, when a listener is added, then it receives onForeground at once")
    func testListenerAddedInForegroundReceivesOnForeground() {
        observer.handle(.becomeActive)
        
        observer.addObserver(listener)
        
        #expect(listener.onForegroundCallCount == 1)
    }
    
    @Test("given a listener inside its catch-up onForeground, when the app moves to the background on another thread, then onBackground waits for the catch-up to end")
    func testLifecycleChangeDoesNotCrossTheCatchUpCall() {
        observer.handle(.becomeActive)
        let backgroundChange = DispatchGroup()
        let crossingListener = CallOrderRecordingListener { [observer] in
            backgroundChange.enter()
            DispatchQueue.global().async {
                observer.handle(.background)
                backgroundChange.leave()
            }
            // Long enough for an unguarded background change to arrive inside this call.
            _ = backgroundChange.wait(timeout: .now() + .milliseconds(200))
        }
        
        observer.addObserver(crossingListener)
        _ = backgroundChange.wait(timeout: .now() + .seconds(2))
        
        #expect(crossingListener.calls == ["onForeground began", "onForeground ended", "onBackground"])
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

// MARK: - CallOrderRecordingListener
/// Records the order of its callbacks, and runs a block inside `onForeground`.
private final class CallOrderRecordingListener: LifecycleEventListener {
    @Synchronized private(set) var calls: [String] = []
    private let duringForeground: () -> Void
    
    init(duringForeground: @escaping () -> Void) {
        self.duringForeground = duringForeground
    }
    
    func onForeground() {
        $calls.modify { $0.append("onForeground began") }
        duringForeground()
        $calls.modify { $0.append("onForeground ended") }
    }
    
    func onBackground() {
        $calls.modify { $0.append("onBackground") }
    }
}
