//
//  LifecycleManagementUtilsTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 28/10/25.
//

import Foundation
import Testing

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

@testable import RudderStackAnalytics

@Suite("LifecycleManagementUtils Tests")
class LifecycleManagementUtilsTests {
    var mockAnalytics: Analytics
    
    init() {
        mockAnalytics = MockProvider.createMockAnalytics()
    }
    
    @Test("when platform-specific notification mapping is checked, then correct mappings are returned")
    func testPlatformSpecificNotificationMapping() {
        #if os(iOS) || os(tvOS)
        #expect(AppLifecycleEvent.background.notificationName == UIApplication.didEnterBackgroundNotification)
        #expect(AppLifecycleEvent.terminate.notificationName == UIApplication.willTerminateNotification)
        #expect(AppLifecycleEvent.foreground.notificationName == UIApplication.willEnterForegroundNotification)
        #expect(AppLifecycleEvent.becomeActive.notificationName == UIApplication.didBecomeActiveNotification)
        
        #elseif os(macOS)
        #expect(AppLifecycleEvent.background.notificationName == NSApplication.didResignActiveNotification)
        #expect(AppLifecycleEvent.terminate.notificationName == NSApplication.willTerminateNotification)
        #expect(AppLifecycleEvent.foreground.notificationName == NSApplication.willBecomeActiveNotification)
        #expect(AppLifecycleEvent.becomeActive.notificationName == NSApplication.didBecomeActiveNotification)
        
        #elseif os(watchOS)
        #expect(AppLifecycleEvent.background.notificationName == WKApplication.didEnterBackgroundNotification)
        #expect(AppLifecycleEvent.terminate.notificationName == Notification.Name("WillTerminate"))
        #expect(AppLifecycleEvent.foreground.notificationName == WKApplication.willEnterForegroundNotification)
        #expect(AppLifecycleEvent.becomeActive.notificationName == WKApplication.didBecomeActiveNotification)
        #endif
    }

    // MARK: - WeakObserver Tests
    
    @Test("when wrapping an observer, then it should be accessible")
    func testWeakObserverWrapping() {
        let observer = MockLifecycleEventListener()
        let weakWrapper = WeakObserver(observer)

        #expect(weakWrapper.observer === observer)
    }

    @Test("when wrapped observer is deallocated, then weak reference should be nil")
    func testWeakObserverDeallocation() {
        var observer: MockLifecycleEventListener? = MockLifecycleEventListener()
        let weakWrapper = WeakObserver(observer!)

        observer = nil

        #expect(weakWrapper.observer == nil)
    }

    @Test("when wrapping multiple observers, then each wrapper should hold its own reference")
    func testMultipleWeakObservers() {
        let observer1 = MockLifecycleEventListener()
        let observer2 = MockLifecycleEventListener()

        let weakWrapper1 = WeakObserver(observer1)
        let weakWrapper2 = WeakObserver(observer2)

        #expect(weakWrapper1.observer === observer1)
        #expect(weakWrapper2.observer === observer2)
        #expect(weakWrapper1.observer !== weakWrapper2.observer)
    }
}
