//
//  macOSLifecycleEvents.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

#if os(macOS)
import Cocoa

public protocol RSmacOSLifecycle {
    func applicationDidResignActive()
    func application(didFinishLaunchingWithOptions launchOptions: [String: Any]?)
    func applicationWillBecomeActive()
    func applicationDidBecomeActive()
    func applicationWillHide()
    func applicationDidHide()
    func applicationDidUnhide()
    func applicationDidUpdate()
    func applicationWillFinishLaunching()
    func applicationWillResignActive()
    func applicationWillUnhide()
    func applicationWillUpdate()
    func applicationWillTerminate()
    func applicationDidChangeScreenParameters()
}

public extension RSmacOSLifecycle {
    func applicationDidResignActive() { }
    func application(didFinishLaunchingWithOptions launchOptions: [String: Any]?) { }
    func applicationWillBecomeActive() { }
    func applicationDidBecomeActive() { }
    func applicationWillHide() { }
    func applicationDidHide() { }
    func applicationDidUnhide() { }
    func applicationDidUpdate() { }
    func applicationWillFinishLaunching() { }
    func applicationWillResignActive() { }
    func applicationWillUnhide() { }
    func applicationWillUpdate() { }
    func applicationWillTerminate() { }
    func applicationDidChangeScreenParameters() { }
}

// swiftlint:disable type_name
class RSmacOSLifecycleMonitor: PlatformPlugin {
    static var specificName = "Rudder_macOSLifecycleMonitor"
    let type = PluginType.utility
    let name = specificName
    var analytics: RSClient?
    
    private var application: NSApplication
    private var appNotifications: [NSNotification.Name] =
        [NSApplication.didFinishLaunchingNotification,
         NSApplication.didResignActiveNotification,
         NSApplication.willBecomeActiveNotification,
         NSApplication.didBecomeActiveNotification,
         NSApplication.didHideNotification,
         NSApplication.didUnhideNotification,
         NSApplication.didUpdateNotification,
         NSApplication.willHideNotification,
         NSApplication.willFinishLaunchingNotification,
         NSApplication.willResignActiveNotification,
         NSApplication.willUnhideNotification,
         NSApplication.willUpdateNotification,
         NSApplication.willTerminateNotification,
         NSApplication.didChangeScreenParametersNotification]
    
    required init() {
        self.application = NSApplication.shared        
        setupListeners()
    }
    
    // swiftlint:disable cyclomatic_complexity
    @objc
    func notificationResponse(notification: NSNotification) {
        switch notification.name {
        case NSApplication.didResignActiveNotification:
            self.didResignActive(notification: notification)
        case NSApplication.willBecomeActiveNotification:
            self.applicationWillBecomeActive(notification: notification)
        case NSApplication.didFinishLaunchingNotification:
            self.applicationDidFinishLaunching(notification: notification)
        case NSApplication.didBecomeActiveNotification:
            self.applicationDidBecomeActive(notification: notification)
        case NSApplication.didHideNotification:
            self.applicationDidHide(notification: notification)
        case NSApplication.didUnhideNotification:
            self.applicationDidUnhide(notification: notification)
        case NSApplication.didUpdateNotification:
            self.applicationDidUpdate(notification: notification)
        case NSApplication.willHideNotification:
            self.applicationWillHide(notification: notification)
        case NSApplication.willFinishLaunchingNotification:
            self.applicationWillFinishLaunching(notification: notification)
        case NSApplication.willResignActiveNotification:
            self.applicationWillResignActive(notification: notification)
        case NSApplication.willUnhideNotification:
            self.applicationWillUnhide(notification: notification)
        case NSApplication.willUpdateNotification:
            self.applicationWillUpdate(notification: notification)
        case NSApplication.willTerminateNotification:
            self.applicationWillTerminate(notification: notification)
        case NSApplication.didChangeScreenParametersNotification:
            self.applicationDidChangeScreenParameters(notification: notification)
        default:
            break
        }
    }
    
    func setupListeners() {
        // Configure the current life cycle events
        let notificationCenter = NotificationCenter.default
        for notification in appNotifications {
            notificationCenter.addObserver(self, selector: #selector(notificationResponse(notification:)), name: notification, object: application)
        }
    }
    
    func applicationWillBecomeActive(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillBecomeActive()
            }
        }
    }
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                let options = notification.userInfo as? [String: Any] ?? nil
                validExt.application(didFinishLaunchingWithOptions: options)
            }
        }
    }
    
    func didResignActive(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidResignActive()
            }
        }
    }
    
    func applicationDidBecomeActive(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidBecomeActive()
            }
        }
    }
    
    func applicationDidHide(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidHide()
            }
        }
    }
    
    func applicationDidUnhide(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidUnhide()
            }
        }
    }

    func applicationDidUpdate(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidUpdate()
            }
        }
    }
    
    func applicationWillHide(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillHide()
            }
        }
    }
    
    func applicationWillFinishLaunching(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillFinishLaunching()
            }
        }
    }
    
    func applicationWillResignActive(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillResignActive()
            }
        }
    }
    
    func applicationWillUnhide(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillUnhide()
            }
        }
    }
    
    func applicationWillUpdate(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillUpdate()
            }
        }
    }
    
    func applicationWillTerminate(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationWillTerminate()
            }
        }
    }
    
    func applicationDidChangeScreenParameters(notification: NSNotification) {
        analytics?.apply { (ext) in
            if let validExt = ext as? RSmacOSLifecycle {
                validExt.applicationDidChangeScreenParameters()
            }
        }
    }
}

extension RudderDestinationPlugin: RSmacOSLifecycle {
    public func applicationDidBecomeActive() {
        enterForeground()
    }
    
    public func applicationWillResignActive() {
        enterBackground()
    }
}

#endif