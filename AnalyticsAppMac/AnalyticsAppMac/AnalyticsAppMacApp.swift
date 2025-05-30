//
//  AnalyticsAppMacApp.swift
//  AnalyticsAppMac
//
//  Created by Satheesh Kannan on 30/05/25.
//

import SwiftUI

// MARK: - AnalyticsAppMacApp
@main
struct AnalyticsAppMacApp: App {
    
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
        
    }
}
