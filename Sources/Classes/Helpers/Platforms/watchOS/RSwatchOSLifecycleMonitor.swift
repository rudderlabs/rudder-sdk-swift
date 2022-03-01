//
//  watchOSLifecycleMonitor.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

#if os(watchOS)

import Foundation
import WatchKit

public protocol RSwatchOSLifecycle {
    func applicationDidFinishLaunching(watchExtension: WKExtension)
    func applicationWillEnterForeground(watchExtension: WKExtension)
    func applicationDidEnterBackground(watchExtension: WKExtension)
    func applicationDidBecomeActive(watchExtension: WKExtension)
    func applicationWillResignActive(watchExtension: WKExtension)
}

public extension RSwatchOSLifecycle {
    func applicationDidFinishLaunching(watchExtension: WKExtension) { }
    func applicationWillEnterForeground(watchExtension: WKExtension) { }
    func applicationDidEnterBackground(watchExtension: WKExtension) { }
    func applicationDidBecomeActive(watchExtension: WKExtension) { }
    func applicationWillResignActive(watchExtension: WKExtension) { }
}

class RSwatchOSLifecycleMonitor: PlatformPlugin {
    var type = PluginType.utility
    var controller: RSClient?
    var wasBackgrounded: Bool = false
    
    private var watchExtension = WKExtension.shared()
    private var appNotifications: [NSNotification.Name] = [WKExtension.applicationDidFinishLaunchingNotification,
                                                           WKExtension.applicationWillEnterForegroundNotification,
                                                           WKExtension.applicationDidEnterBackgroundNotification,
                                                           WKExtension.applicationDidBecomeActiveNotification,
                                                           WKExtension.applicationWillResignActiveNotification]
    
    required init() {
        watchExtension = WKExtension.shared()
        setupListeners()
    }
    
    @objc
    func notificationResponse(notification: NSNotification) {
        switch notification.name {
        case WKExtension.applicationDidFinishLaunchingNotification:
            self.applicationDidFinishLaunching(notification: notification)
        case WKExtension.applicationWillEnterForegroundNotification:
            self.applicationWillEnterForeground(notification: notification)
        case WKExtension.applicationDidEnterBackgroundNotification:
            self.applicationDidEnterBackground(notification: notification)
        case WKExtension.applicationDidBecomeActiveNotification:
            self.applicationDidBecomeActive(notification: notification)
        case WKExtension.applicationWillResignActiveNotification:
            self.applicationWillResignActive(notification: notification)
        default:
            break
        }
    }
    
    func setupListeners() {
        // Configure the current life cycle events
        let notificationCenter = NotificationCenter.default
        for notification in appNotifications {
            notificationCenter.addObserver(self, selector: #selector(notificationResponse(notification:)), name: notification, object: nil)
        }
    }
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        controller?.apply { (ext) in
            if let validExt = ext as? RSwatchOSLifecycle {
                validExt.applicationDidFinishLaunching(watchExtension: watchExtension)
            }
        }
    }
    
    func applicationWillEnterForeground(notification: NSNotification) {
        // watchOS will receive this after didFinishLaunching, which is different
        // from iOS, so ignore until we've been backgrounded at least once.
        if wasBackgrounded == false { return }
        
        controller?.apply { (ext) in
            if let validExt = ext as? RSwatchOSLifecycle {
                validExt.applicationWillEnterForeground(watchExtension: watchExtension)
            }
        }
    }
    
    func applicationDidEnterBackground(notification: NSNotification) {
        // make sure to denote that we were backgrounded.
        wasBackgrounded = true
        
        controller?.apply { (ext) in
            if let validExt = ext as? RSwatchOSLifecycle {
                validExt.applicationDidEnterBackground(watchExtension: watchExtension)
            }
        }
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        controller?.apply { (ext) in
            if let validExt = ext as? RSwatchOSLifecycle {
                validExt.applicationDidBecomeActive(watchExtension: watchExtension)
            }
        }
    }
    
    func applicationWillResignActive(notification: NSNotification) {
        controller?.apply { (ext) in
            if let validExt = ext as? RSwatchOSLifecycle {
                validExt.applicationWillResignActive(watchExtension: watchExtension)
            }
        }
    }

}

// MARK: - Segment Destination Extension

extension RSDestinationPlugin: RSwatchOSLifecycle {
    public func applicationWillEnterForeground(watchExtension: WKExtension) {
        enterForeground()
    }
    
    public func applicationDidEnterBackground(watchExtension: WKExtension) {
        enterBackground()
    }
}

#endif
