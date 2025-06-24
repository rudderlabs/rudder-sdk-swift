//
//  AnalyticsManager.swift
//  macOSExample
//
//  Created by Satheesh Kannan on 30/05/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - AnalyticsManager
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
    
    func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(screenName: name, category: category, properties: properties, options: options)
    }
    
    func group(id: String, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        self.analytics?.group(groupId: id, traits: traits, options: options)
    }
    
    func identify(userId: String? = nil, traits: RudderTraits? = nil, options: RudderOption? = nil) {
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
    
    var traits: RudderTraits? {
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
