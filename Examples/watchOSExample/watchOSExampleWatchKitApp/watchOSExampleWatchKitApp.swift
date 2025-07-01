//
//  watchOSExampleApp.swift
//  watchOSExampleWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
//

import SwiftUI

// MARK: - WatchKit App
@main
struct watchOSExampleWatchKitApp: App {
    
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
        // Initialize the Analytics SDK
        AnalyticsManager.shared.initializeAnalyticsSDK()
    }
}
