//
//  iOSDelegation.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

import UIKit

// MARK: - Remote Notifications

protocol RemoteNotifications: Plugin {
    func registeredForRemoteNotifications(deviceToken: Data)
    func failedToRegisterForRemoteNotification(error: Error?)
    func receivedRemoteNotification(userInfo: [AnyHashable: Any])
    func handleAction(identifier: String, userInfo: [String: Any])
}

extension RemoteNotifications {
    func registeredForRemoteNotifications(deviceToken: Data) {}
    func failedToRegisterForRemoteNotification(error: Error?) {}
    func receivedRemoteNotification(userInfo: [AnyHashable: Any]) {}
    func handleAction(identifier: String, userInfo: [String: Any]) {}
}

extension RSClient {
    func registeredForRemoteNotifications(deviceToken: Data) {
        setDeviceToken(deviceToken.hexString)
        
        apply { plugin in
            if let p = plugin as? RemoteNotifications {
                p.registeredForRemoteNotifications(deviceToken: deviceToken)
            }
        }
    }
    
    func failedToRegisterForRemoteNotification(error: Error?) {
        apply { plugin in
            if let p = plugin as? RemoteNotifications {
                p.failedToRegisterForRemoteNotification(error: error)
            }
        }
    }
    
    func receivedRemoteNotification(userInfo: [AnyHashable: Any]) {
        apply { plugin in
            if let p = plugin as? RemoteNotifications {
                p.receivedRemoteNotification(userInfo: userInfo)
            }
        }
    }
    
    func handleAction(identifier: String, userInfo: [String: Any]) {
        apply { plugin in
            if let p = plugin as? RemoteNotifications {
                p.handleAction(identifier: identifier, userInfo: userInfo)
            }
        }
    }
}

// MARK: - User Activity

protocol UserActivities {
    func continueUserActivity(_ activity: NSUserActivity)
}

extension UserActivities {
    func continueUserActivity(_ activity: NSUserActivity) {}
}

extension RSClient {
    func continueUserActivity(_ activity: NSUserActivity) {
        apply { plugin in
            if let p = plugin as? UserActivities {
                p.continueUserActivity(activity)
            }
        }
    }
}

// MARK: - Opening a URL

protocol OpeningURLs {
    func openURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
}

extension OpeningURLs {
    func openURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) {}
}

extension RSClient {
    func openURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) {
        apply { plugin in
            if let p = plugin as? OpeningURLs {
                p.openURL(url, options: options)
            }
        }
    }
}

#endif
