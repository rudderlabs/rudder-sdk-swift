//
//  RSClient.swift
//  RudderStack
//
//  Created by Pallab Maiti on 05/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc
open class RSClient: NSObject {
    var config: RSConfig
    var controller: RSController
    var serverConfig: RSServerConfig?
    var error: NSError?
    
    /// Initialize this instance of RSClient with a given configuration setup.
    /// - Parameters:
    ///    - config: The configuration to use
    @objc
    public init(config: RSConfig) {
        self.config = config
        serverConfig = RSUserDefaults.getServerConfig()
        controller = RSController()
        
        super.init()
        addPlugins()
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
            .applyRawEventData()
        process(message: message)
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
    public func screen(_ screenName: String, category: String? = nil, properties: [String: String]? = nil, option: RSOption? = nil) {
        let message = ScreenMessage(title: screenName, category: category, properties: properties, option: option)
            .applyRawEventData()
        process(message: message)
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
    public func group(_ groupId: String, traits: [String: String]? = nil, option: RSOption? = nil) {
        let message = GroupMessage(groupId: groupId, traits: traits, option: option)
            .applyRawEventData()
        process(message: message)
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
    public func alias(_ newId: String, option: RSOption? = nil) {
        let message = AliasMessage(newId: newId, option: option)
            .applyAlias(newId: newId, client: self)
            .applyRawEventData()
        setUserId(newId)
        process(message: message)
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
    public func identify(_ userId: String, traits: [String: Any]? = nil, option: RSOption? = nil) {
        let message = IdentifyMessage(userId: userId, traits: traits, option: option)
            .applyRawEventData()
        setUserId(userId)
        process(message: message)
    }
}

// MARK: - System Modifiers

extension RSClient {
    /// Returns the anonymousId currently in use.
    @objc
    public var anonymousId: String {
        if let anonymousId = RSUserDefaults.getAnonymousId() {
            return anonymousId
        }
        return ""
    }
    
    /// Returns the userId that was specified in the last identify call.
    @objc
    public var userId: String? {
        if let userIdPlugin = self.find(pluginType: RSUserIdPlugin.self) {
            return userIdPlugin.userId
        }
        return nil
    }
    
    /// Returns the traits that were specified in the last identify call.
    @objc
    public var context: MessageContext? {
        if let contextPlugin = self.find(pluginType: RSContextPlugin.self) {
            return contextPlugin.context
        }
        return nil
    }
    
    /// Tells this instance of Analytics to flush any queued events. This command will also
    /// be sent to each plugin present in the system.
    @objc
    public func flush() {
        apply { plugin in
            if let p = plugin as? RSEventPlugin {
                p.flush()
            }
        }
    }
    
    /// Resets this instance of Analytics to a clean slate.  Traits, UserID's, anonymousId, etc are all cleared or reset.  This
    /// command will also be sent to each plugin present in the system.
    @objc
    public func reset() {
        apply { plugin in
            if let p = plugin as? RSEventPlugin {
                p.reset()
            }
        }
    }
    
    /// Retrieve the version of this library in use.
    /// - Returns: A string representing the version in "BREAKING.FEATURE.FIX" format.
    @objc
    public var version: String {
        return RSVersion
    }
    
    /// Retrieve the version of this library in use.
    /// - Returns: A string representing the version in "BREAKING.FEATURE.FIX" format.
    @objc
    public var configuration: RSConfig {
        return config
    }
}

extension RSClient {
    /**
     Applies the supplied closure to the currently loaded set of plugins.
     NOTE: This does not apply to plugins contained within DestinationPlugins.
     
     - Parameter closure: A closure that takes an plugin to be operated on as a parameter.
     
     */
    func apply(closure: (RSPlugin) -> Void) {
        controller.apply(closure)
    }
    
    /**
     Adds a new plugin to the currently loaded set.
     
     - Parameter plugin: The plugin to be added.
     - Returns: Returns the name of the supplied plugin.
     
     */
    @discardableResult
    public func add(plugin: RSPlugin) -> RSPlugin {
        plugin.configure(client: self)
        controller.add(plugin: plugin)
        return plugin
    }
    
    /**
     Removes and unloads plugins with a matching name from the system.
     
     - Parameter pluginName: An plugin name.
     */
    func remove(plugin: RSPlugin) {
        controller.remove(plugin: plugin)
    }
    
    func find<T: RSPlugin>(pluginType: T.Type) -> T? {
        return controller.find(pluginType: pluginType)
    }
}

extension RSClient {
    func process(message: RSMessage) {
        switch message {
        case let e as TrackMessage:
            controller.process(incomingEvent: e)
        case let e as IdentifyMessage:
            controller.process(incomingEvent: e)
        case let e as ScreenMessage:
            controller.process(incomingEvent: e)
        case let e as GroupMessage:
            controller.process(incomingEvent: e)
        case let e as AliasMessage:
            controller.process(incomingEvent: e)
        default:
            break
        }
    }    
}
