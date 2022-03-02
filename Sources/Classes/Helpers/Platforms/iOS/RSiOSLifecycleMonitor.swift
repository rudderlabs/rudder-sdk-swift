//
//  LifecycleEvents.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import Foundation
import UIKit

protocol RSiOSLifecycle {
    func applicationDidEnterBackground(application: UIApplication?)
    func applicationWillEnterForeground(application: UIApplication?)
    func application(_ application: UIApplication?, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    func applicationDidBecomeActive(application: UIApplication?)
    func applicationWillResignActive(application: UIApplication?)
    func applicationDidReceiveMemoryWarning(application: UIApplication?)
    func applicationWillTerminate(application: UIApplication?)
    func applicationSignificantTimeChange(application: UIApplication?)
    func applicationBackgroundRefreshDidChange(application: UIApplication?, refreshStatus: UIBackgroundRefreshStatus)
}

extension RSiOSLifecycle {
    func applicationDidEnterBackground(application: UIApplication?) { }
    func applicationWillEnterForeground(application: UIApplication?) { }
    func application(_ application: UIApplication?, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) { }
    func applicationDidBecomeActive(application: UIApplication?) { }
    func applicationWillResignActive(application: UIApplication?) { }
    func applicationDidReceiveMemoryWarning(application: UIApplication?) { }
    func applicationWillTerminate(application: UIApplication?) { }
    func applicationSignificantTimeChange(application: UIApplication?) { }
    func applicationBackgroundRefreshDidChange(application: UIApplication?, refreshStatus: UIBackgroundRefreshStatus) { }
}

class RSiOSLifecycleMonitor: RSPlatformPlugin {
    let type = PluginType.utility
    var client: RSClient?
    
    private var application: UIApplication = UIApplication.shared
    private var appNotifications: [NSNotification.Name] = [UIApplication.didEnterBackgroundNotification,
                                                           UIApplication.willEnterForegroundNotification,
                                                           UIApplication.didFinishLaunchingNotification,
                                                           UIApplication.didBecomeActiveNotification,
                                                           UIApplication.willResignActiveNotification,
                                                           UIApplication.didReceiveMemoryWarningNotification,
                                                           UIApplication.willTerminateNotification,
                                                           UIApplication.significantTimeChangeNotification,
                                                           UIApplication.backgroundRefreshStatusDidChangeNotification]

    required init() {
        setupListeners()
    }
    
    @objc
    func notificationResponse(notification: NSNotification) {        
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            self.didEnterBackground(notification: notification)
        case UIApplication.willEnterForegroundNotification:
            self.applicationWillEnterForeground(notification: notification)
        case UIApplication.didFinishLaunchingNotification:
            self.didFinishLaunching(notification: notification)
        case UIApplication.didBecomeActiveNotification:
            self.didBecomeActive(notification: notification)
        case UIApplication.willResignActiveNotification:
            self.willResignActive(notification: notification)
        case UIApplication.didReceiveMemoryWarningNotification:
            self.didReceiveMemoryWarning(notification: notification)
        case UIApplication.significantTimeChangeNotification:
            self.significantTimeChange(notification: notification)
        case UIApplication.backgroundRefreshStatusDidChangeNotification:
            self.backgroundRefreshDidChange(notification: notification)
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
    
    func applicationWillEnterForeground(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationWillEnterForeground(application: application)
            }
        }
    }
    
    func didEnterBackground(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationDidEnterBackground(application: application)
            }
        }
    }
    
    func didFinishLaunching(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                let options = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any] ?? nil
                validExt.application(application, didFinishLaunchingWithOptions: options)
            }
        }
    }

    func didBecomeActive(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationDidBecomeActive(application: application)
            }
        }
    }
    
    func willResignActive(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationWillResignActive(application: application)
            }
        }
    }
    
    func didReceiveMemoryWarning(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationDidReceiveMemoryWarning(application: application)
            }
        }
    }
    
    func willTerminate(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationWillTerminate(application: application)
            }
        }
    }
    
    func significantTimeChange(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationSignificantTimeChange(application: application)
            }
        }
    }
    
    func backgroundRefreshDidChange(notification: NSNotification) {
        client?.apply { (ext) in
            if let validExt = ext as? RSiOSLifecycle {
                validExt.applicationBackgroundRefreshDidChange(application: application,
                                                               refreshStatus: application.backgroundRefreshStatus)
            }
        }
    }
}

// MARK: - Segment Destination Extension

extension RudderDestinationPlugin: RSiOSLifecycle {
    func applicationWillEnterForeground(application: UIApplication?) {
        enterForeground()
    }
    
    func applicationDidEnterBackground(application: UIApplication?) {
        enterBackground()
    }
}

/*extension SegmentDestination.UploadTaskInfo {
    init(url: URL, task: URLSessionDataTask) {
        self.url = url
        self.task = task
        
        if let application = UIApplication.safeShared {
            let taskIdentifier = application.beginBackgroundTask { [self] in
                self.task.suspend()
                self.cleanup?()
            }
            self.taskID = taskIdentifier.rawValue
            
            self.cleanup = { [self] in
                application.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: self.taskID))
            }
        }
    }
}*/

#endif
