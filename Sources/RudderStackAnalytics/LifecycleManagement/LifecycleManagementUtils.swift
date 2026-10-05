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

    /**
     Whether the app is on screen now. Call it on the main thread.

     An app that is on screen but not yet active counts too. The platform reports that state while the user
     opens the app, and never while the system runs the app with no screen.
     */
    static var isInForeground: Bool {
#if os(iOS) || os(tvOS)
        // `UIApplication.shared` is unavailable to app extensions, so it is reached by key path.
        guard !isAppExtension, let application = UIApplication.value(forKeyPath: "sharedApplication") as? UIApplication else { return false }
        return application.applicationState != .background
#elseif os(macOS)
        // On macOS an app that is not the active one counts as in the background.
        return NSApp?.isActive ?? false
#elseif os(watchOS)
        // Only a single-target watch app runs as `WKApplication`. Any other process waits for its first foreground notification.
        guard isSingleTargetWatchApp else { return false }
        return WKApplication.shared().applicationState != .background
#endif
    }

#if os(iOS) || os(tvOS)
    private static var isAppExtension: Bool {
        return Bundle.main.bundlePath.hasSuffix(".appex")
    }
#elseif os(watchOS)
    private static var isSingleTargetWatchApp: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "WKApplication") as? Bool == true
    }
#endif
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
