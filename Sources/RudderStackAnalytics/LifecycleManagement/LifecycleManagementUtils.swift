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

// MARK: - AppState
/**
 The app state as the platform reports it now.
 */
enum AppState {

    /// Whether the user sees the app now. Call it on the main thread.
    static var isActive: Bool {
#if os(iOS) || os(tvOS)
        // `UIApplication.shared` is unavailable to app extensions, so it is reached by key path.
        guard !isAppExtension, let application = UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication else { return false }
        return application.applicationState == .active
#elseif os(macOS)
        return NSApp?.isActive ?? false
#elseif os(watchOS)
        return WKApplication.shared().applicationState == .active
#endif
    }

    private static var isAppExtension: Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }
}

// MARK: - LifecycleEventListener
/**
 Receives the app's lifecycle changes.

 `onForeground` and `onBackground` arrive once per change of state, never twice in a row.
 */
protocol LifecycleEventListener: AnyObject {
    func onBackground()
    func onForeground()
    func onTerminate()
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
