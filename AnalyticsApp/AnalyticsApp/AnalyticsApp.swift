//
//  AnalyticsAppApp.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI

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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Note: Since bluetooth doesn't have a completion block for user response, ask `Bluetooth` permission always at last.
        self.permissionManager.requestPermissions([.idfa, .bluetooth]) {
            print("All required permissions requested..")
            AnalyticsManager.shared.initializeAnalyticsSDK()
        }
        return true
    }
}
