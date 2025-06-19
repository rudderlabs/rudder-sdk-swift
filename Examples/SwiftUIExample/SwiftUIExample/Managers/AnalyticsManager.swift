//
//  AnalyticsManager.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - AnalyticsManager
class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    private init() {}
    
    private var analytics: AnalyticsClient?
    
    func initializeAnalyticsSDK() {
        LoggerAnalytics.logLevel = .verbose // Set the log level for analytics
        
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
        self.analytics = AnalyticsClient(configuration: config)
        
        //Add external plugin to analytics..
        self.analytics?.add(plugin: AdvertisingIdPlugin())
        self.analytics?.add(plugin: BluetoothInfoPlugin())
        
        let customOption = RudderOption(integrations: ["CleverTap": true], customContext: ["plugin_key": "plugin_value"], externalIds: [ExternalId(type: "external_id_type", id: "external_id")])
        
        self.analytics?.add(plugin: OptionPlugin(option: customOption))
    }
}

// MARK: - Rudder methods
extension AnalyticsManager {
    func identify(userId: String? = nil, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        self.analytics?.identify(userId: userId, traits: traits, options: options)
    }
    
    func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(screenName: name, category: category, properties: properties, options: options)
    }
    
    func group(id: String, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        self.analytics?.group(groupId: id, traits: traits, options: options)
    }
    
    func alias(newId: String, previousId: String? = nil, options: RudderOption? = nil) {
        self.analytics?.alias(newId: newId, previousId: previousId, options: options)
    }
    
    func addPlugin(_ plugin: Plugin) {
        self.analytics?.add(plugin: plugin)
    }
    
    func flush() {
        self.analytics?.flush()
    }
    
    func reset() {
        self.analytics?.reset()
    }
    
    func startSession(sessionId: UInt64? = nil) {
        self.analytics?.startSession(sessionId: sessionId)
    }
    
    func endSession() {
        self.analytics?.endSession()
    }
    
    func shutdown() {
        self.analytics?.shutdown()
    }
    
    var anonymousId: String? {
        return self.analytics?.anonymousId
    }
    
    var sessionId: UInt64? {
        return self.analytics?.sessionId
    }
    
    var userId: String? {
        return self.analytics?.userId
    }
    
    func openURL(_ url: URL, options: [String: Any]? = nil) {
        self.analytics?.openURL(url, options: options)
    }
}

