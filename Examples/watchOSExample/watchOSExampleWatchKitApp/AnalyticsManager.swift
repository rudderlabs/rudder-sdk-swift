//
//  AnalyticsManager.swift
//  watchOSExampleWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - AnalyticsManager
/**
 A singleton wrapper around the `RudderStackAnalytics` SDK that provides a centralized interface for tracking user events, managing user identity, and handling analytics configurations across the SwiftUI application.
 
 ## Features
    - Event tracking (track, screen, group, identify, alias)
    - User identity and trait management
    - Session management with start/end capabilities
    - Plugin system for extending analytics functionality
    - Deep link tracking support

 ## Usage
 ```swift
 // Initialize the analytics SDK (call this once at app startup)
 AnalyticsManager.shared.initializeAnalyticsSDK()
 
 // Track events
 AnalyticsManager.shared.track(name: "Button Clicked", properties: ["button": "login"])
 
 // Identify users
 AnalyticsManager.shared.identify(userId: "user123", traits: ["email": "user@example.com"])
 
 // Track screens
 AnalyticsManager.shared.screen(name: "Dashboard", category: "Main")
 
 // Manage sessions
 AnalyticsManager.shared.startSession()
 AnalyticsManager.shared.endSession()
  ```
  - Note: This is a singleton class. Use `AnalyticsManager.shared` to access the instance.
 */
class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    private init() {}
    
    private var analytics: Analytics?
    
    func initializeAnalyticsSDK() {
        LoggerAnalytics.logLevel = .verbose // Set the log level for analytics
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
        self.analytics = Analytics(configuration: config)
    }
}

// MARK: - Rudder methods
extension AnalyticsManager {
    
    // MARK: - Event Tracking
    
    func track(name: String, properties: Properties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: Properties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(screenName: name, category: category, properties: properties, options: options)
    }
    
    func group(id: String, traits: Traits? = nil, options: RudderOption? = nil) {
        self.analytics?.group(groupId: id, traits: traits, options: options)
    }
    
    func identify(userId: String? = nil, traits: Traits? = nil, options: RudderOption? = nil) {
        self.analytics?.identify(userId: userId, traits: traits, options: options)
    }
    
    func alias(newId: String, previousId: String? = nil, options: RudderOption? = nil) {
        self.analytics?.alias(newId: newId, previousId: previousId, options: options)
    }
    
    func flush() {
        self.analytics?.flush()
    }
    
    // MARK: - User Management
    
    func reset() {
        self.analytics?.reset()
    }
    
    var anonymousId: String? {
        return self.analytics?.anonymousId
    }
    
    var userId: String? {
        return self.analytics?.userId
    }
    
    var traits: Traits? {
        return self.analytics?.traits
    }
    
    // MARK: - Session Management
    
    func startSession(sessionId: UInt64? = nil) {
        self.analytics?.startSession(sessionId: sessionId)
    }
    
    func endSession() {
        self.analytics?.endSession()
    }
    
    var sessionId: UInt64? {
        return self.analytics?.sessionId
    }
    
    // MARK: - Plugin Management
    
    func addPlugin(_ plugin: Plugin) {
        self.analytics?.add(plugin: plugin)
    }
    
    // MARK: - System Management
    
    func shutdown() {
        self.analytics?.shutdown()
    }
    
    // MARK: - Deep Link Tracking
    
    func openURL(_ url: URL, options: [String: Any]? = nil) {
        self.analytics?.open(url: url, options: options)
    }
}
