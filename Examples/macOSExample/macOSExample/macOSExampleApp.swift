//
//  macOSExampleApp.swift
//  macOSExample
//
//  Created by Satheesh Kannan on 30/05/25.
//

import SwiftUI

// MARK: - macOSExampleApp
@main
struct macOSExampleApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AnalyticsManager.shared.initializeAnalyticsSDK()
    }
}
