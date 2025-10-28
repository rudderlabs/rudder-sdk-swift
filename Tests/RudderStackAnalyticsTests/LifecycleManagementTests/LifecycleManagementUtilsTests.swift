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
        mockAnalytics = SwiftTestMockProvider.createMockAnalytics()
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
    
    @Test("when initialized, LifecycleSessionWrapper should set up components correctly")
    func testLifecycleSessionWrapperInitialization() {
        
        let lifecycleSessionWrapper = LifecycleSessionWrapper(analytics: mockAnalytics)
        
        #expect(lifecycleSessionWrapper.lifecycleObserver != nil)
        #expect(lifecycleSessionWrapper.sessionHandler != nil)
        #expect(lifecycleSessionWrapper.lifecycleObserver?.analytics === mockAnalytics)
        #expect(lifecycleSessionWrapper.sessionHandler?.analytics === mockAnalytics)
    }
    
    @Test("when invalidating, LifecycleSessionWrapper should clean up components in correct order")
    func testLifecycleSessionWrapperInvalidate() {
        let lifecycleSessionWrapper = LifecycleSessionWrapper(analytics: mockAnalytics)
        
        #expect(lifecycleSessionWrapper.lifecycleObserver != nil)
        #expect(lifecycleSessionWrapper.sessionHandler != nil)
        
        lifecycleSessionWrapper.invalidate()
        
        #expect(lifecycleSessionWrapper.sessionHandler == nil)
        #expect(lifecycleSessionWrapper.lifecycleObserver == nil)
    }
    
    @Test("when integrated, lifecycle events should work through wrapper")
    func testIntegratedLifecycleEventHandling() {
        let lifecycleSessionWrapper = LifecycleSessionWrapper(analytics: mockAnalytics)
        let mockListener = MockLifecycleEventListener()
        
        lifecycleSessionWrapper.lifecycleObserver?.addObserver(mockListener)
        NotificationCenter.default.post(name: AppLifecycleEvent.foreground.notificationName, object: nil)
        NotificationCenter.default.post(name: AppLifecycleEvent.background.notificationName, object: nil)
        
        #expect(mockListener.onForegroundCalled == true)
        #expect(mockListener.onBackgroundCalled == true)
    }
    
    @Test("when initialized, wrapper components should reference the same Analytics instance")
    func testWrapperComponentsAnalyticsReference() {
        let lifecycleSessionWrapper = LifecycleSessionWrapper(analytics: mockAnalytics)
        
        #expect(lifecycleSessionWrapper.lifecycleObserver?.analytics === mockAnalytics)
        #expect(lifecycleSessionWrapper.sessionHandler?.analytics === mockAnalytics)
    }
}
