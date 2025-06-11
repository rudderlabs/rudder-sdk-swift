//
//  AnalyticsAppApp.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI
import UserNotifications

// MARK: - AnalyticsAppApp
@main
struct AnalyticsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    AnalyticsManager.shared.openURL(url)
                }
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let permissionManager = PermissionManager()
    private var permissionsRequested = false
    private var pushToken: String = "" {
        didSet {
            if permissionsRequested, !pushToken.isEmpty {
                AnalyticsManager.shared.addPlugin(SetPushTokenPlugin(pushToken: pushToken))
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        self.permissionManager.requestPermissions([.idfa, .pushNotification, .bluetooth]) {
            print("All required permissions requested..")
            self.permissionsRequested = true
            AnalyticsManager.shared.initializeAnalyticsSDK()
            
            if !self.pushToken.isEmpty {
                AnalyticsManager.shared.addPlugin(SetPushTokenPlugin(pushToken: self.pushToken))
            }
        }
        return true
    }
}

// MARK: - APNS
extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.pushToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(pushToken)")
        self.permissionManager.didRegisterForRemoteNotifications()
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error.localizedDescription)")
    }
}
