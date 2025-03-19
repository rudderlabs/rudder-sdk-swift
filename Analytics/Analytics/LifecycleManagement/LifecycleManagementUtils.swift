//
//  LifecycleManagementUtils.swift
//  Analytics
//
//  Created by Satheesh Kannan on 10/03/25.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - AppLifecycleEvent
enum AppLifecycleEvent: CaseIterable {
    case background
    case terminate
    case foreground
    case becomeActive
    
    var notificationName: Notification.Name {
#if os(macOS)
        switch self {
        case .background: return NSApplication.didResignActiveNotification
        case .terminate: return NSApplication.willTerminateNotification
        case .foreground: return NSApplication.didBecomeActiveNotification
        case .becomeActive: return NSApplication.didBecomeActiveNotification
        }
#else
        switch self {
        case .background: return UIApplication.didEnterBackgroundNotification
        case .terminate: return UIApplication.willTerminateNotification
        case .foreground: return UIApplication.willEnterForegroundNotification
        case .becomeActive: return UIApplication.didBecomeActiveNotification
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
