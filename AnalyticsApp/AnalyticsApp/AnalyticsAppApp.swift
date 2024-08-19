//
//  AnalyticsAppApp.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI
import Analytics

@main
struct AnalyticsAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsManager.shared.initializeAnalyticsSDK()
        return true
    }
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    var analytics: Analytics?
   
    private init() {}
    
    func initializeAnalyticsSDK() {
        let config = Configuration(writeKey: "", dataPlaneUrl: "")
        self.analytics = Analytics(configuration: config)
    }
}
