//
//  AnalyticsManager.swift
//  AnalyticsAppWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
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
    }
    
    func track(name: String, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.track(name: name, properties: properties, options: options)
    }
    
    func screen(name: String, category: String? = nil, properties: RudderProperties? = nil, options: RudderOption? = nil) {
        self.analytics?.screen(name: name, category: category, properties: properties, options: options)
    }
    
    func flush() {
        self.analytics?.flush()
    }
}
