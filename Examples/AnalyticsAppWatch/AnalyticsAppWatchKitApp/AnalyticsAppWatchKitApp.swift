//
//  AnalyticsAppWatchApp.swift
//  AnalyticsAppWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
//

import SwiftUI

// MARK: - WatchKit App
@main
struct AnalyticsAppWatchKitApp: App {
    
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, WKApplicationDelegate {
    
    func applicationDidFinishLaunching() {
        AnalyticsManager.shared.initializeAnalyticsSDK()
    }
}
