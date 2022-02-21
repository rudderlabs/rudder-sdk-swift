//
//  Analytics.swift
//  analytics-swift
//
//  Created by Brandon Sneed on 11/17/20.
//

import Foundation

// MARK: - Base Setup

public class Analytics {
    internal var config: RSConfig
    internal var messageHandler: RSMessageHandler
    public var timeline: Timeline

    /// Initialize this instance of RSClient with a given configuration setup.
    /// - Parameters:
    ///    - config: The configuration to use
    @objc
    public init(config: RSConfig) {
        self.config = config
        messageHandler = RSMessageHandler()
//        store = Store()
//        storage = Storage(store: self.store, writeKey: configuration.values.writeKey)
        timeline = Timeline()
        
        // provide our default state
//        store.provide(state: System.defaultState(configuration: configuration, from: storage))
//        store.provide(state: UserInfo.defaultState(from: storage))
        
        // Get everything running
        platformStartup()
    }
    
    
    /**
     API for track your event
     - Parameters:
        - eventName: Name of the event you want to track
        - properties: Properties you want to pass with the track call
        - option: Options related to this track call
     # Example #
     ```
     let option = RSOption()
     RSClient.sharedInstance().track("Button clicked", properties: [:], option: option)
     ```
     */

    @objc
    public func track(_ eventName: String, properties: [String: Any]? = nil, option: RSOption? = nil) {
        let message = TrackMessage(event: eventName, properties: properties, option: option)
        processMessage(message)
    }
    
    /**
     API for record screen
     - Parameters:
        - screenName: Name of the screen
        - properties: Properties you want to pass with the screen call
        - option: Options related to this screen call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().screen("MyViewController", properties: [:], options: options)
     ```
     */
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any], option: RSOption) {
        let message = ScreenMessage(title: screenName, properties: properties, option: option)
        processMessage(message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - groupId: Group ID you want your user to attach to
        - traits: Traits of the group
        - option: Options related to this group call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("A1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func group(_ groupId: String, traits: [String: Any], option: RSOption) {
        let message = GroupMessage(groupId: groupId, traits: traits, option: option)
        processMessage(message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - newId: New userId for the user
        - option: Options related to this alias call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", options: options)
     ```
     */
    
    @objc
    public func alias(_ newId: String, option: RSOption) {
        let message = AliasMessage(newId: newId, option: option)
        processMessage(message)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - userId: User id of your user
        - traits: Other user properties
        - option: Options related to this identify call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func identify(_ userId: String, traits: [String: Any], option: RSOption) {
        let message = IdentifyMessage(userId: userId, traits: traits, option: option)
        processMessage(message)
    }
    
    internal func processMessage(_ message: Message) {
        timeline.process(incomingEvent: message)
    }
    
//    internal var configuration: Configuration
//    internal var store: Store
//    internal var storage: Storage
    
    /// Enabled/disables debug logging to trace your data going through the SDK.
//    public static var debugLogsEnabled = false {
//        didSet {
//            SegmentLog.loggingEnabled = debugLogsEnabled
//        }
//    }
        
    /// Initialize this instance of Analytics with a given configuration setup.
    /// - Parameters:
    ///    - configuration: The configuration to use
//    public init(configuration: Configuration) {
//        self.configuration = configuration
//
//        store = Store()
//        storage = Storage(store: self.store, writeKey: configuration.values.writeKey)
//        timeline = Timeline()
//
//        // provide our default state
//        store.provide(state: System.defaultState(configuration: configuration, from: storage))
//        store.provide(state: UserInfo.defaultState(from: storage))
//
//        // Get everything running
//        platformStartup()
//    }
    
//    internal func process<E: Message>(incomingEvent: E) {
//        let event = incomingEvent.applyRawEventData(store: store)
//        _ = timeline.process(incomingEvent: event)
//    }
    
    /// Process a raw event through the system.  Useful when one needs to queue and replay events at a later time.
    /// - Parameters:
    ///   - event: An event conforming to RawEvent that will be processed.
//    public func process(event: Message) {
//        switch event {
//        case let e as TrackMessage:
//            timeline.process(incomingEvent: e)
//        case let e as IdentifyMessage:
//            timeline.process(incomingEvent: e)
//        case let e as ScreenMessage:
//            timeline.process(incomingEvent: e)
//        case let e as GroupMessage:
//            timeline.process(incomingEvent: e)
//        case let e as AliasMessage:
//            timeline.process(incomingEvent: e)
//        default:
//            break
//        }
//    }
}

// MARK: - System Modifiers

extension Analytics {
    /// Returns the anonymousId currently in use.
    public var anonymousId: String {
        if let userInfo: UserInfo = store.currentState() {
            return userInfo.anonymousId
        }
        return ""
    }
    
    /// Returns the userId that was specified in the last identify call.
    public var userId: String? {
        if let userInfo: UserInfo = store.currentState() {
            return userInfo.userId
        }
        return nil
    }
    
    /// Returns the traits that were specified in the last identify call.
    public func traits<T: Codable>() -> T? {
        if let userInfo: UserInfo = store.currentState() {
            return userInfo.traits?.codableValue()
        }
        return nil
    }
    
    /// Tells this instance of Analytics to flush any queued events up to Segment.com.  This command will also
    /// be sent to each plugin present in the system.
    public func flush() {
        apply { plugin in
            if let p = plugin as? EventPlugin {
                p.flush()
            }
        }
    }
    
    /// Resets this instance of Analytics to a clean slate.  Traits, UserID's, anonymousId, etc are all cleared or reset.  This
    /// command will also be sent to each plugin present in the system.
    public func reset() {
        store.dispatch(action: UserInfo.ResetAction())
        apply { plugin in
            if let p = plugin as? EventPlugin {
                p.reset()
            }
        }
    }
    
    /// Retrieve the version of this library in use.
    /// - Returns: A string representing the version in "BREAKING.FEATURE.FIX" format.
    public func version() -> String {
        return Analytics.version()
    }
    
    /// Retrieve the version of this library in use.
    /// - Returns: A string representing the version in "BREAKING.FEATURE.FIX" format.
    public static func version() -> String {
        return __segment_version
    }
}

extension Analytics {
    /// Manually retrieve the settings that were supplied from Segment.com.
    /// - Returns: A Settings object containing integration settings, tracking plan, etc.
    public func settings() -> Settings? {
        var settings: Settings?
        if let system: System = store.currentState() {
            settings = system.settings
        }
        return settings
    }
    
    /// Manually enable a destination plugin.  This is useful when a given DestinationPlugin doesn't have any Segment tie-ins at all.
    /// This will allow the destination to be processed in the same way within this library.
    /// - Parameters:
    ///   - plugin: The destination plugin to enable.
    public func manuallyEnableDestination(plugin: DestinationPlugin) {
        self.store.dispatch(action: System.AddDestinationToSettingsAction(key: plugin.key))
    }

}
