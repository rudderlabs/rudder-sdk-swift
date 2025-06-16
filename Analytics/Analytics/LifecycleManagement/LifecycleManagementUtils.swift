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
    case didFinishLaunching
    case background
    case terminate
    case foreground
    case becomeActive
    
    var notificationName: Notification.Name {
#if os(iOS) || os(tvOS)
        switch self {
        case .didFinishLaunching: return UIApplication.didFinishLaunchingNotification
        case .background: return UIApplication.didEnterBackgroundNotification
        case .terminate: return UIApplication.willTerminateNotification
        case .foreground: return UIApplication.willEnterForegroundNotification
        case .becomeActive: return UIApplication.didBecomeActiveNotification
        }
        
#elseif os(macOS)
        switch self {
        case .didFinishLaunching: return NSApplication.didFinishLaunchingNotification
        case .background: return NSApplication.didResignActiveNotification
        case .terminate: return NSApplication.willTerminateNotification
        case .foreground: return NSApplication.willBecomeActiveNotification
        case .becomeActive: return NSApplication.didBecomeActiveNotification
        }
        
#elseif os(watchOS)
        switch self {
        case .didFinishLaunching: return WKApplication.didFinishLaunchingNotification
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
    func onDidFinishLaunching(options: [AnyHashable: Any]?)
    func onBackground()
    func onForeground()
    func onTerminate()
    func onBecomeActive()
}

extension LifecycleEventListener {
    func onDidFinishLaunching(options: [AnyHashable: Any]?) {
        /* Default implementation (no-op) */
    }
    
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

// MARK: - LifecycleManagementUtils

class LifecycleManagementUtils {
    private init() {
        /* Default implementation (no-op) */
    }
    
    /// Processes application launch options and extracts relevant properties for analytics
    /// - Parameter options: The launch options dictionary from application launch
    /// - Returns: Dictionary of properties extracted from launch options
    static func processLaunchOptions(_ options: [AnyHashable: Any]?) -> [String: Any] {
        var properties: [String: Any] = [:]
        guard let options = options else { return properties }
        
        #if os(iOS) || os(tvOS)
        // iOS and tvOS specific launch options
        let url = options[UIApplication.LaunchOptionsKey.url] as? URL
        properties["url"] = url?.absoluteString ?? ""
        
        let sourceApplication = options[UIApplication.LaunchOptionsKey.sourceApplication] as? String
        properties["referring_application"] = sourceApplication ?? ""
        
        #elseif os(macOS)
        // macOS specific launch options
        let urls = options["NSApplicationLaunchUserNotificationKey"] as? [URL] ?? []
        properties["url"] = urls.first?.absoluteString ?? ""
        
        let sourceApplication = options["NSApplicationLaunchUserNotificationKey"] as? String ?? ""
        properties["referring_application"] = sourceApplication
        #endif
        
        return properties
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
    
    init(analytics: AnalyticsClient) {
        self.lifecycleObserver = LifecycleObserver(analytics: analytics)
        self.sessionHandler = SessionHandler(analytics: analytics)
    }
    
    func tearDown() {
        // Don't change the order..
        self.sessionHandler = nil
        self.lifecycleObserver = nil
    }
}

// MARK: - AnalyticsClient
/**
 Provides convenient access to the session handler and lifecycle observer from the lifecycle session handler.
 */
extension AnalyticsClient {
    var sessionHandler: SessionHandler? {
        return self.lifecycleSessionWrapper?.sessionHandler
    }
    
    var lifecycleObserver: LifecycleObserver? {
        return self.lifecycleSessionWrapper?.lifecycleObserver
    }
}
