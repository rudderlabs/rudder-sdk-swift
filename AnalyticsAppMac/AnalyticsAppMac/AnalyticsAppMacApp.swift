//
//  AnalyticsAppMacApp.swift
//  AnalyticsAppMac
//
//  Created by Satheesh Kannan on 30/05/25.
//

import SwiftUI
import Analytics

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
    
    var analytics: AnalyticsClient?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
    }
}

// MARK: - Analytics Helper

extension AppDelegate {
    
    static var `default`: AppDelegate { NSApplication.shared.delegate as! AppDelegate }
    
    func initializeAnalyticsSDK() {
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com", logLevel: .verbose)
        self.analytics = AnalyticsClient(configuration: config)
    }
    
    func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(name: name, category: category, properties: properties, options: options)
    }
}
