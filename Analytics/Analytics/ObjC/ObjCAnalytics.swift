//
//  ObjCAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

// MARK: - ObjCAnalytics
/**
 A wrapper class that exposes the Swift `AnalyticsClient` to Objective-C.
 */
@objc(RSAAnalytics)
public final class ObjCAnalytics: NSObject {
    
    let analytics: AnalyticsClient
    
    /**
     Initializes the analytics client using the provided Objective-C configuration.
     
     - Parameter configuration: The configuration object containing settings and storage details.
     */
    @objc
    public init(configuration: Configuration) {
        self.analytics = AnalyticsClient(configuration: configuration)
    }
    
    /**
     Initializes the analytics wrapper with an existing `AnalyticsClient` instance.
     
     - Parameter analytics: The analytics client to wrap.
     */
    public init(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
}

// MARK: - Session
extension ObjCAnalytics {
    
    /**
     Starts a new analytics session with an automatically generated session ID.
     */
    @objc
    public func startSession() {
        self.analytics.startSession()
    }
    
    /**
     Starts a new analytics session using the specified session ID.
     
     - Parameter sessionId: The session ID to use. Must be non-negative.
     */
    @objc
    public func startSession(sessionId: NSNumber) {
        if sessionId.int64Value < 0 {
            LoggerAnalytics.error(log: "Negative session IDs are invalid.")
            return
        }
        self.analytics.startSession(sessionId: sessionId.uint64Value)
    }
    
    /**
     Ends the current analytics session.
     */
    @objc
    public func endSession() {
        self.analytics.endSession()
    }
    
    /**
     The current session ID, if available.
     */
    @objc public var sessionId: NSNumber? {
        guard let sessionId = self.analytics.sessionId else { return nil }
        return NSNumber(value: sessionId)
    }
}
// MARK: - Internnal Events

extension ObjCAnalytics {
    
    // MARK: - Track
    
    private func internalTrack(_ name: String, properties: [String: Any]?, options: RudderOption?) {
        self.analytics.track(name: name, properties: properties?.objCSanitized, options: options)
    }
    
    // MARK: - Screen
    
    private func internalScreen(_ name: String, category: String?, properties: [String: Any]?, options: RudderOption?) {
        self.analytics.screen(name: name, category: category, properties: properties?.objCSanitized, options: options)
    }
    
    // MARK: - Group
    
    private func internalGroup(_ id: String, traits: [String: Any]?, options: RudderOption?) {
        self.analytics.group(groupId: id, traits: traits?.objCSanitized, options: options)
    }
    
    // MARK: - Identify
    
    private func internalIdentify(_ userId: String?, traits: [String: Any]?, options: RudderOption?) {
        self.analytics.identify(userId: userId, traits: traits?.objCSanitized, options: options)
    }
    
    // MARK: - Alias
    
    private func internalAlias(_ userId: String, previousId: String?, options: RudderOption?) {
        self.analytics.alias(newId: userId, previousId: previousId, options: options)
    }
    
}

// MARK: - Events

extension ObjCAnalytics {
    
    // MARK: - Track

    /**
     Tracks an event by name.
     
     - Parameter name: The name of the event.
     */
    @objc
    public func track(_ name: String) {
        self.internalTrack(name, properties: nil, options: nil)
    }

    /**
     Tracks an event by name with properties.
     
     - Parameters:
       - name: The name of the event.
       - properties: A dictionary of properties for the event.
     */
    @objc
    public func track(_ name: String, properties: [String: Any]) {
        self.internalTrack(name, properties: properties, options: nil)
    }

    /**
     Tracks an event by name with options.
     
     - Parameters:
       - name: The name of the event.
       - options: Additional tracking options.
     */
    @objc
    public func track(_ name: String, options: RudderOption) {
        self.internalTrack(name, properties: nil, options: options)
    }

    /**
     Tracks an event by name with properties and options.
     
     - Parameters:
       - name: The name of the event.
       - properties: A dictionary of properties for the event.
       - options: Additional tracking options.
     */
    @objc
    public func track(_ name: String, properties: [String: Any], options: RudderOption) {
        self.internalTrack(name, properties: properties, options: options)
    }

    // MARK: - Screen

    /**
     Tracks a screen view by name.
     
     - Parameter name: The name of the screen.
     */
    @objc
    public func screen(_ name: String) {
        self.internalScreen(name, category: nil, properties: nil, options: nil)
    }

    /**
     Tracks a screen view by name and category.
     
     - Parameters:
       - name: The screen name.
       - category: The category of the screen.
     */
    @objc
    public func screen(_ name: String, category: String) {
        self.internalScreen(name, category: category, properties: nil, options: nil)
    }

    /**
     Tracks a screen view with properties.
     
     - Parameters:
       - name: The screen name.
       - properties: Screen properties.
     */
    @objc
    public func screen(_ name: String, properties: [String: Any]) {
        self.internalScreen(name, category: nil, properties: properties, options: nil)
    }

    /**
     Tracks a screen view with options.
     
     - Parameters:
       - name: The screen name.
       - options: Additional options for screen tracking.
     */
    @objc
    public func screen(_ name: String, options: RudderOption) {
        self.internalScreen(name, category: nil, properties: nil, options: options)
    }

    /**
     Tracks a screen view with category and properties.
     
     - Parameters:
       - name: The screen name.
       - category: The screen category.
       - properties: Additional screen properties.
     */
    @objc
    public func screen(_ name: String, category: String, properties: [String: Any]) {
        self.internalScreen(name, category: category, properties: properties, options: nil)
    }

    /**
     Tracks a screen view with category and options.
     
     - Parameters:
       - name: The screen name.
       - category: The screen category.
       - options: Additional options.
     */
    @objc
    public func screen(_ name: String, category: String, options: RudderOption) {
        self.internalScreen(name, category: category, properties: nil, options: options)
    }

    /**
     Tracks a screen view with properties and options.
     
     - Parameters:
       - name: The screen name.
       - properties: Additional screen properties.
       - options: Additional options.
     */
    @objc
    public func screen(_ name: String, properties: [String: Any], options: RudderOption) {
        self.internalScreen(name, category: nil, properties: properties, options: options)
    }

    /**
     Tracks a screen view with category, properties, and options.
     
     - Parameters:
       - name: The screen name.
       - category: The screen category.
       - properties: Additional screen properties.
       - options: Additional options.
     */
    @objc
    public func screen(_ name: String, category: String, properties: [String: Any], options: RudderOption) {
        self.internalScreen(name, category: category, properties: properties, options: options)
    }

    // MARK: - Group

    /**
     Associates the user with a group.
     
     - Parameter id: The group identifier.
     */
    @objc
    public func group(_ groupId: String) {
        self.internalGroup(groupId, traits: nil, options: nil)
    }

    /**
     Associates the user with a group and traits.
     
     - Parameters:
       - id: The group identifier.
       - traits: Traits to associate with the group.
     */
    @objc
    public func group(_ groupId: String, traits: [String: Any]) {
        self.internalGroup(groupId, traits: traits, options: nil)
    }

    /**
     Associates the user with a group and options.
     
     - Parameters:
       - id: The group identifier.
       - options: Additional options.
     */
    @objc
    public func group(_ groupId: String, options: RudderOption) {
        self.internalGroup(groupId, traits: nil, options: options)
    }

    /**
     Associates the user with a group, traits, and options.
     
     - Parameters:
       - id: The group identifier.
       - traits: Traits to associate.
       - options: Additional options.
     */
    @objc
    public func group(_ groupId: String, traits: [String: Any], options: RudderOption) {
        self.internalGroup(groupId, traits: traits, options: options)
    }

    // MARK: - Identify

    /**
     Identifies a user by user ID.
     
     - Parameter userId: The user ID.
     */
    @objc
    public func identify(_ userId: String) {
        self.internalIdentify(userId, traits: nil, options: nil)
    }

    /**
     Identifies a user by traits only.
     
     - Parameter traits: Traits associated with the user.
     */
    @objc
    public func identify(traits: [String: Any]) {
        self.internalIdentify(nil, traits: traits, options: nil)
    }

    /**
     Identifies a user by user ID and traits.
     
     - Parameters:
       - userId: The user ID.
       - traits: Traits associated with the user.
     */
    @objc
    public func identify(_ userId: String, traits: [String: Any]) {
        self.internalIdentify(userId, traits: traits, options: nil)
    }

    /**
     Identifies a user by user ID and options.
     
     - Parameters:
       - userId: The user ID.
       - options: Additional options.
     */
    @objc
    public func identify(_ userId: String, options: RudderOption) {
        self.internalIdentify(userId, traits: nil, options: options)
    }

    /**
     Identifies a user by traits and options.
     
     - Parameters:
       - traits: Traits associated with the user.
       - options: Additional options.
     */
    @objc
    public func identify(traits: [String: Any], options: RudderOption) {
        self.internalIdentify(nil, traits: traits, options: options)
    }

    /**
     Identifies a user by user ID, traits, and options.
     
     - Parameters:
       - userId: The user ID.
       - traits: Traits associated with the user.
       - options: Additional options.
     */
    @objc
    public func identify(_ userId: String, traits: [String: Any], options: RudderOption) {
        self.internalIdentify(userId, traits: traits, options: options)
    }

    // MARK: - Alias

    /**
     Aliases a user ID with a new ID.
     
     - Parameter userId: The new user ID.
     */
    @objc
    public func alias(_ userId: String) {
        self.internalAlias(userId, previousId: nil, options: nil)
    }

    /**
     Aliases a user ID with a previous ID.
     
     - Parameters:
       - userId: The new user ID.
       - previousId: The previous user ID.
     */
    @objc
    public func alias(_ userId: String, previousId: String) {
        self.internalAlias(userId, previousId: previousId, options: nil)
    }

    /**
     Aliases a user ID with options.
     
     - Parameters:
       - newId: The new user ID.
       - options: Additional options.
     */
    @objc
    public func alias(_ newId: String, options: RudderOption) {
        self.internalAlias(newId, previousId: nil, options: options)
    }

    /**
     Aliases a user ID with a previous ID and options.
     
     - Parameters:
       - newId: The new user ID.
       - previousId: The previous user ID.
       - options: Additional options.
     */
    @objc
    public func alias(_ newId: String, previousId: String, options: RudderOption) {
        self.internalAlias(newId, previousId: previousId, options: options)
    }
}
// MARK: - Others

extension ObjCAnalytics {
    /**
     Sends any queued analytics data to the server.
     */
    @objc
    public func flush() {
        self.analytics.flush()
    }

    /**
     Shuts down the analytics client.
     */
    @objc
    public func shutdown() {
        self.analytics.shutdown()
    }

    /**
     Resets analytics state.
     */
    @objc
    public func reset() {
        self.analytics.reset()
    }

    /**
     Sets a custom logger for analytics logging.
     
     - Parameter logger: An Objective-C compatible logger.
     */
    @objc(setCustomLogger:)
    public func setLogger(_ logger: ObjCLogger) {
        let adaptedLogger = ObjCLoggerAdapter(logger: logger)
        self.analytics.setLogger(logger: adaptedLogger)
    }
}

extension ObjCAnalytics {
    /**
     The anonymous ID used for tracking unidentified users.
     */
    @objc public var anonymousId: String? {
        return self.analytics.anonymousId
    }

    /**
     The currently identified user's ID, if available.
     */
    @objc public var userId: String? {
        return self.analytics.userId
    }

    /**
     Traits associated with the currently identified user.
     */
    @objc public var traits: [String: Any]? {
        return self.analytics.traits
    }
}

extension ObjCAnalytics {
    /**
     Adds a plugin to the analytics client.
     
     - Parameter plugin: An Objective-C compatible plugin.
     */
    @objc
    public func addPlugin(_ plugin: ObjCPlugin) {
        let adaptedPlugin = ObjCPluginAdapter(objcPlugin: plugin)
        analytics.addPlugin(adaptedPlugin)
    }
}
