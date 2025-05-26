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
    
    // MARK: - Track
    
    private func internalTrack(_ name: String, properties: [String: Any]?, options: ObjCOption?) {
        self.analytics.track(name: name, properties: properties, options: options?.option)
    }
    
    @objc
    public func track(_ name: String) {
        self.internalTrack(name, properties: nil, options: nil)
    }
    
    @objc
    public func track(_ name: String, properties: [String: Any]) {
        self.internalTrack(name, properties: properties, options: nil)
    }
    
    @objc
    public func track(_ name: String, options: ObjCOption) {
        self.internalTrack(name, properties: nil, options: options)
    }
    
    @objc
    public func track(_ name: String, properties: [String: Any], options: ObjCOption) {
        self.internalTrack(name, properties: properties, options: options)
    }
    
    // MARK: - Screen
    
    private func internalScreen(_ name: String, category: String?, properties: [String: Any]?, options: ObjCOption?) {
        self.analytics.screen(name: name, category: category, properties: properties, options: options?.option)
    }
    
    @objc
    public func screen(_ name: String) {
        self.internalScreen(name, category: nil, properties: nil, options: nil)
    }
    
    @objc
    public func screen(_ name: String, category: String) {
        self.internalScreen(name, category: category, properties: nil, options: nil)
    }
    
    @objc
    public func screen(_ name: String, properties: [String: Any]) {
        self.internalScreen(name, category: nil, properties: properties, options: nil)
    }
    
    @objc
    public func screen(_ name: String, options: ObjCOption) {
        self.internalScreen(name, category: nil, properties: nil, options: options)
    }
    
    @objc
    public func screen(_ name: String, category: String, properties: [String: Any]) {
        self.internalScreen(name, category: category, properties: properties, options: nil)
    }
    
    @objc
    public func screen(_ name: String, category: String, options: ObjCOption) {
        self.internalScreen(name, category: category, properties: nil, options: options)
    }
    
    @objc
    public func screen(_ name: String, properties: [String: Any], options: ObjCOption) {
        self.internalScreen(name, category: nil, properties: properties, options: options)
    }
    
    @objc
    public func screen(_ name: String, category: String, properties: [String: Any], options: ObjCOption) {
        self.internalScreen(name, category: category, properties: properties, options: options)
    }
    
    // MARK: - Group
    
    private func internalGroup(_ id: String, traits: [String: Any]?, options: ObjCOption?) {
        self.analytics.group(id: id, traits: traits, options: options?.option)
    }
    
    @objc
    public func group(_ id: String) {
        self.internalGroup(id, traits: nil, options: nil)
    }
    
    @objc
    public func group(_ id: String, traits: [String: Any]) {
        self.internalGroup(id, traits: traits, options: nil)
    }
    
    @objc
    public func group(_ id: String, options: ObjCOption) {
        self.internalGroup(id, traits: nil, options: options)
    }
    
    @objc
    public func group(_ id: String, traits: [String: Any], options: ObjCOption) {
        self.internalGroup(id, traits: traits, options: options)
    }
    
    // MARK: - Identify
    
    private func internalIdentify(_ userId: String?, traits: [String: Any]?, options: ObjCOption?) {
        self.analytics.identify(userId: userId, traits: traits, options: options?.option)
    }
    
    @objc
    public func identify(_ userId: String) {
        self.internalIdentify(userId, traits: nil, options: nil)
    }
    
    @objc
    public func identify(traits: [String: Any]) {
        self.internalIdentify(nil, traits: traits, options: nil)
    }
    
    @objc
    public func identify(_ userId: String, traits: [String: Any]) {
        self.internalIdentify(userId, traits: traits, options: nil)
    }
    
    @objc
    public func identify(_ userId: String, options: ObjCOption) {
        self.internalIdentify(userId, traits: nil, options: options)
    }
    
    @objc
    public func identify(traits: [String: Any], options: ObjCOption) {
        self.internalIdentify(nil, traits: traits, options: options)
    }
    
    @objc
    public func identify(_ userId: String, traits: [String: Any], options: ObjCOption) {
        self.internalIdentify(userId, traits: traits, options: options)
    }
    
    // MARK: - Alias
    
    private func internalAlias(_ userId: String, previousId: String?, options: ObjCOption?) {
        self.analytics.alias(newId: userId, previousId: previousId, options: options?.option)
    }
    
    @objc
    public func alias(_ userId: String) {
        self.internalAlias(userId, previousId: nil, options: nil)
    }
    
    @objc
    public func alias(_ userId: String, previousId: String) {
        self.internalAlias(userId, previousId: previousId, options: nil)
    }
    
    @objc
    public func alias(_ newId: String, options: ObjCOption) {
        self.internalAlias(newId, previousId: nil, options: options)
    }
    
    @objc
    public func alias(_ newId: String, previousId: String, options: ObjCOption) {
        self.internalAlias(newId, previousId: previousId, options: options)
    }
    
}

// MARK: - Others

extension ObjCAnalytics {
    
    // MARK: - Flush
    @objc
    public func flush() {
        self.analytics.flush()
    }
    
    // MARK: - Shutdown
    @objc
    public func shutdown() {
        self.analytics.shutdown()
    }
    
    // MARK: - Reset
    @objc
    public func reset(_ clearAnonymousId: Bool) {
        clearAnonymousId ? self.analytics.reset(clearAnonymousId: true) : self.analytics.reset()
    }
    
    // MARK: - Logger
    @objc
    public func setLogger(_ logger: ObjCLogger) {
        let adaptedLogger = ObjCLoggerAdapter(logger: logger)
        self.analytics.setLogger(logger: adaptedLogger)
    }
}
