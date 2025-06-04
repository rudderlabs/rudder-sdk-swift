//
//  AnalyticsAppTvApp.swift
//  AnalyticsAppTv
//
//  Created by Satheesh Kannan on 04/06/25.
//

import SwiftUI

@main
struct AnalyticsAppTvApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AnalyticsManager.shared.initializeAnalyticsSDK()
        return true
    }
}
