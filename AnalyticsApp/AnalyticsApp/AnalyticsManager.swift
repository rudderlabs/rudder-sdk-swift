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
    }
}

extension AnalyticsManager: Logger {
    
    var currentLogLevel: LogLevel { .debug }
    
    func debug(tag: String, log: String) {
        print("\(tag) : \(log)")
    }
}

