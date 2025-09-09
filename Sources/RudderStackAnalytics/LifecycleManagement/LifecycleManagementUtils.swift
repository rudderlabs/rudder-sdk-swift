//
//  LifecycleManagementUtils.swift
//  Analytics
//
//  Created by Satheesh Kannan on 10/03/25.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - AppLifecycleEvent
enum AppLifecycleEvent: CaseIterable {
    case background
    case terminate
    case foreground
    case becomeActive
    
    var notificationName: Notification.Name {
#if os(iOS) || os(tvOS)
        switch self {
        case .background: return UIApplication.didEnterBackgroundNotification
        case .terminate: return UIApplication.willTerminateNotification
        case .foreground: return UIApplication.willEnterForegroundNotification
        case .becomeActive: return UIApplication.didBecomeActiveNotification
        }
        
#elseif os(macOS)
        switch self {
        case .background: return NSApplication.didResignActiveNotification
        case .terminate: return NSApplication.willTerminateNotification
        case .foreground: return NSApplication.willBecomeActiveNotification
        case .becomeActive: return NSApplication.didBecomeActiveNotification
        }
        
#elseif os(watchOS)
        switch self {
        case .background: return WKApplication.didEnterBackgroundNotification
        case .terminate: return Notification.Name("WillTerminate")
        case .foreground: return WKApplication.willEnterForegroundNotification
        case .becomeActive: return WKApplication.didBecomeActiveNotification
        }
#endif
    }
}

// MARK: - LifecycleEventListener
protocol LifecycleEventListener: AnyObject {
    func onBackground()
    func onForeground()
    func onTerminate()
    func onBecomeActive()
}

extension LifecycleEventListener {
    func onBackground() {
        /* Default implementation (no-op) */
    }
    
    func onForeground() {
        /* Default implementation (no-op) */
    }
    
    func onTerminate() {
        /* Default implementation (no-op) */
    }
    
    func onBecomeActive() {
        /* Default implementation (no-op) */
    }
}

// MARK: - WeakObserver
/**
 Wrapper to hold weak references to observers
 */
class WeakObserver {
    weak var observer: LifecycleEventListener?
    
    init(_ observer: LifecycleEventListener) {
        self.observer = observer
    }
}

// MARK: - LifecycleSessionWrapper
/**
 A wrapper that integrates lifecycle observation and session handling for analytics tracking.
 */
class LifecycleSessionWrapper {
    var lifecycleObserver: LifecycleObserver?
    var sessionHandler: SessionHandler?
    
    init(analytics: Analytics) {
        self.lifecycleObserver = LifecycleObserver(analytics: analytics)
        self.sessionHandler = SessionHandler(analytics: analytics)
    }
    
    func invalidate() {
        // Don't change the order..
        self.sessionHandler = nil
        self.lifecycleObserver = nil
    }
}

// MARK: - Analytics
/**
 Provides convenient access to the session handler and lifecycle observer from the lifecycle session handler.
 */
extension Analytics {
    var sessionHandler: SessionHandler? {
        return self.lifecycleSessionWrapper?.sessionHandler
    }
    
    var lifecycleObserver: LifecycleObserver? {
        return self.lifecycleSessionWrapper?.lifecycleObserver
    }
}
