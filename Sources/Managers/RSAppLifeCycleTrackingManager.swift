//
//  RSAppLifeCycleTrackingManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import UIKit

class RSAppLifeCycleTrackingManager: RSTrackingManager {
    
    func track() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidFinishLaunchingNotification(_:)), name: UIApplication.didFinishLaunchingNotification, object: UIApplication.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: UIApplication.shared)
    }
    
    @objc
    func handleDidFinishLaunchingNotification(_ notification: Notification) {
        guard RSClient.shared.eventManager.config?.trackLifecycleEvents == true else {
            return
        }
        let previousVersion = RSUserDefaults.getBuildVersionCode()
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if previousVersion == nil {
            RSClient.shared.track("Application Installed", properties: ["version": currentVersion ?? ""])
        } else if previousVersion != currentVersion {
            RSClient.shared.track("Application Updated", properties: ["previous_version": previousVersion ?? "",
                                                                      "version": currentVersion ?? ""])
        }
        RSClient.shared.track("Application Opened", properties: ["from_background": false,
                                                                 "version": currentVersion ?? "",
                                                                 "referring_application": notification.userInfo?[UIApplication.LaunchOptionsKey.sourceApplication] ?? "",
                                                                 "url": notification.userInfo?[UIApplication.LaunchOptionsKey.url] ?? ""])
        RSUserDefaults.saveBuildVersionCode(currentVersion)
    }
    
    @objc
    func handleWillEnterForegroundNotification() {
        guard RSClient.shared.eventManager.config?.trackLifecycleEvents == true else {
            return
        }
        RSClient.shared.track("Application Opened", properties: ["from_background": true])
    }
    
    @objc
    func handleDidEnterBackgroundNotification() {
        guard RSClient.shared.eventManager.config?.trackLifecycleEvents == true else {
            return
        }
        RSClient.shared.track("Application Backgrounded")
    }
}
