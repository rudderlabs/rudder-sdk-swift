//
//  AnalyticsManager.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Foundation
import Analytics

// MARK: - AnalyticsManager
class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    private init() {}
    
    private var analytics: AnalyticsClient?
    
    func initializeAnalyticsSDK() {
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com", logLevel: .verbose)
        self.analytics = AnalyticsClient(configuration: config)
        
        //Add external plugin to analytics..
        self.analytics?.addPlugin(AdvertisingIdPlugin())
        self.analytics?.addPlugin(BluetoothInfoPlugin())
        
        let customOption = RudderOption(integrations: ["CleverTap": true], customContext: ["plugin_key": "plugin_value"], externalIds: [ExternalId(type: "external_id_type", id: "external_id")])
        
        self.analytics?.addPlugin(OptionPlugin(option: customOption))
    }
}

// MARK: - Rudder methods
extension AnalyticsManager {
    func identify(userId: String, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        self.analytics?.identify(userId: userId, traits: traits, options: options)
    }
    
    func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(name: name, category: category, properties: properties, options: options)
    }
    
    func group(id: String, traits: RudderTraits? = nil, options: RudderOption? = nil) {
        self.analytics?.group(id: id, traits: traits, options: options)
    }
    
    func alias(newId: String, previousId: String? = nil, options: RudderOption? = nil) {
        self.analytics?.alias(newId: newId, previousId: previousId, options: options)
    }
    
    func flush() {
        self.analytics?.flush()
    }
    
    func reset(_ clearAnonymousId: Bool) {
        self.analytics?.reset(clearAnonymousId: clearAnonymousId)
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
        get { self.analytics?.anonymousId }
        set { if let newId = newValue { self.analytics?.anonymousId = newId } }
    }
    
    var sessionId: UInt64? {
        return self.analytics?.sessionId
    }
    
    func openURL(_ url: URL, options: [String: Any]? = nil) {
        self.analytics?.openURL(url, options: options)
    }
}

