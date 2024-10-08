//
//  AnalyticsAppApp.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI
import Analytics

// MARK: - AnalyticsAppApp
@main
struct AnalyticsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        AnalyticsManager.shared.initializeAnalyticsSDK()
        return true
    }
}

// MARK: - AnalyticsManager
class AnalyticsManager: Logger {
    
    static let shared = AnalyticsManager()
    
    var analytics: AnalyticsClient?
   
    private init() {}
    
    func initializeAnalyticsSDK() {
        let config = Configuration(writeKey: "exmple_write_key", dataPlaneUrl: "https://data-plane.example.com", controlPlaneUrl: "https://control-plane.example.com", logger: self)
        self.analytics = AnalyticsClient(configuration: config)
    }
    
    var currentLogLevel: LogLevel = .debug
    
    func debug(tag: String, log: String) {
        print("\(tag) : \(log)")
    }
}
