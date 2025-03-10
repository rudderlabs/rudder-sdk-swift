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

enum AppLifecycleEvent: CaseIterable {
    case background
    case terminate
    case foreground
    
    var notificationName: Notification.Name {
#if os(macOS)
        switch self {
        case .background: return NSApplication.didResignActiveNotification
        case .terminate: return NSApplication.willTerminateNotification
        case .foreground: return NSApplication.didBecomeActiveNotification
        }
#else
        switch self {
        case .background: return UIApplication.didEnterBackgroundNotification
        case .terminate: return UIApplication.willTerminateNotification
        case .foreground: return UIApplication.willEnterForegroundNotification
        }
#endif
    }
}

protocol LifecycleEventObserver: AnyObject {
    func onBackground()
    func onForeground()
    func onTerminate()
}

// Wrapper to hold weak references to observers
class WeakObserver {
    weak var observer: LifecycleEventObserver?
    
    init(_ observer: LifecycleEventObserver) {
        self.observer = observer
    }
}
