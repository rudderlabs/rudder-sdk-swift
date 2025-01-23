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
        let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com", logger: self)
        self.analytics = AnalyticsClient(configuration: config)
        
        //Add external plugin to analytics..
        self.analytics?.addPlugin(AdvertisingIdPlugin())
    }
}

// MARK: - Rudder methods
extension AnalyticsManager {
    func track(name: String, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOptions? = nil) {
        self.analytics?.screen(name: name, category: category, properties: properties, options: options)
    }
    
    func group(id: String, traits: RudderTraits? = nil, options: RudderOptions? = nil) {
        self.analytics?.group(id: id, traits: traits, options: options)
    }
    
    func flush() {
        self.analytics?.flush()
    }
    
    var anonymousId: String? {
        get { self.analytics?.anonymousId }
        set { if let newId = newValue { self.analytics?.anonymousId = newId } }
    }
}

// MARK: - Logger
extension AnalyticsManager: Logger {
    
    var currentLogLevel: LogLevel { .debug }
    
    func debug(tag: String, log: String) {
        print("\(tag) : \(log)")
    }
}

