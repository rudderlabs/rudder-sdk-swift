//
//  AppDelegate.swift
//  SwiftExample
//
//  Created by Satheesh Kannan on 19/04/25.
//

import UIKit
import RudderStackAnalytics

// MARK: - AppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var analytics: Analytics?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.initializeAnalyticsSDK() // Initialize the analytics SDK
        return true
    }

    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - Analytics Helper

extension AppDelegate {
    
    static var `default`: AppDelegate { UIApplication.shared.delegate as! AppDelegate }
    
    func initializeAnalyticsSDK() {
        // Set the log level for analytics
        LoggerAnalytics.logLevel = .verbose

        // Initialize the RudderStack Analytics SDK 
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
        self.analytics = Analytics(configuration: config)
        
        // Add plugins for automatic screen tracking
        self.analytics?.add(plugin: UIKitAutomaticScreenTrackingPlugin())
    }
    
    // MARK: - Rudder methods
    /** 
     * They wrap the underlying RudderStack Analytics SDK methods for ease of use.
     */
    func track(name: String, properties: Properties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: Properties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(screenName: name, category: category, properties: properties, options: options)
    }
}

// MARK: - UIStoryboard

extension UIStoryboard {
    static var main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }
}
