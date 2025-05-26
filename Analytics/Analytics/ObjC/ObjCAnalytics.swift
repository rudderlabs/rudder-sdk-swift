//
//  ObjCAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

// MARK: - ObjCAnalytics

@objc(RSAnalytics)
public final class ObjCAnalytics: NSObject {
    
    let analytics: AnalyticsClient
    
    @objc
    public init(configuration: ObjCConfiguration) {
        self.analytics = AnalyticsClient(configuration: configuration.configuration)
    }
}

// MARK: - Session
extension ObjCAnalytics {
    
    @objc
    public func startSession() {
        self.analytics.startSession()
    }
    
    @objc
    public func startSession(sessionId: NSNumber) {
        if sessionId.int64Value < 0 {
            LoggerAnalytics.error(log: "Negative session IDs are invalid.")
            return
        }
        self.analytics.startSession(sessionId: sessionId.uint64Value)
    }
    
    @objc
    public func endSession() {
        self.analytics.endSession()
    }
    
    @objc
    public var sessionId: NSNumber? {
        guard let sessionId = self.analytics.sessionId else { return nil }
        return NSNumber(value: sessionId)
    }
}

// MARK: - Events

extension ObjCAnalytics {
    
    @objc
    public func track(_ name: String) {
        self.track(name, properties: nil, options: nil)
    }
    
    @objc
    public func track(_ name: String, properties: [String: Any]?) {
        self.track(name, properties: properties, options: nil)
    }
    
    @objc
    public func track(_ name: String, properties: [String: Any]?, options: ObjCOption?) {
        self.analytics.track(name: name, properties: properties, options: options?.option)
    }
}
