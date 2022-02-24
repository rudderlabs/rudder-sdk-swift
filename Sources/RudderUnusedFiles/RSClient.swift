//
//  RSClient.swift
//  Rudder
//
//  Created by Pallab Maiti on 04/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation
/**
 Entry point for Rudder SDK
 */
/*
@objc open class RSClient: NSObject {
    internal static let shared = RSClient()
    internal let eventManager = RSEventManager()
    internal let logger = RSLogger()
    internal let messageHandler = RSMessageHandler()

    private override init() {
        
    }
    
    /**
     API for getting RSClient instance
     - Returns: Instance of _RSClient_
     # Example #
     ```
     RSClient.sharedInstance()
     ```
     */
    
    @objc
    public static func sharedInstance() -> RSClient {
        return shared
    }
    
    /**
     API for getting RSClient instance
     - Parameters:
        - writeKey: The iOS key from Rudder dashboard when you create a source
     - Returns: Instance of _RSClient_
     # Example #
     ```
     RSClient.getInstance("abcd1234")
     ```
     */
    
    @objc
    public static func getInstance(_ writeKey: String) -> RSClient {
        return getInstance(writeKey, config: RSConfig(), options: RSOption())
    }
    
    /**
     API for getting RSClient instance with custom values for settings through RSConfig
     - Parameters:
        - writeKey: The iOS key from Rudder dashboard when you create a source
        - config: Instance of RudderConfig for customised settings
     - Returns: Instance of _RSClient_
     # Example #
     ```
     let config = RSConfig()
     RSClient.getInstance("abcd1234", config: config)
     ```
     */
    
    @objc
    public static func getInstance(_ writeKey: String, config: RSConfig) -> RSClient {
        return getInstance(writeKey, config: config, options: RSOption())
    }
    
    /**
     API for getting RSClient instance with custom values for settings through RSConfig and custom options through RSOption
     - Parameters:
        - writeKey: The iOS key from Rudder dashboard when you create a source
        - config: Instance of RudderConfig for customised settings
        - options: Instance of RudderOption for customizing integrations to which events to be sent
     - Returns: Instance of _RSClient_
     # Example #
     ```
     let config = RSConfig()
     let options = RSOption()
     RSClient.getInstance("abcd1234", config: config, options: options)
     ```
     */
    
    @objc
    public static func getInstance(_ writeKey: String, config: RSConfig, options: RSOption) -> RSClient {
        RSClient.shared.eventManager.configure(writeKey: writeKey, config: config, options: options)
        return shared
    }
    
    /**
     API for track your event
     - Parameters:
        - eventName: Name of the event you want to track
     # Example #
     ```
     RSClient.sharedInstance().track("Button clicked")
     ```
     */
    
    @objc
    public func track(_ eventName: String) {
        messageHandler.handleTrackEvent(eventName)
    }
    
    /**
     API for track your event
     - Parameters:
        - eventName: Name of the event you want to track
        - properties: Properties you want to pass with the track call
     # Example #
     ```
     RSClient.sharedInstance().track("Button clicked", properties: [:])
     ```
     */
    
    @objc
    public func track(_ eventName: String, properties: [String: Any]) {
        messageHandler.handleTrackEvent(eventName, properties: properties)
    }
    
    /**
     API for track your event
     - Parameters:
        - eventName: Name of the event you want to track
        - properties: Properties you want to pass with the track call
        - options: Options related to this track call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().track("Button clicked", properties: [:], options: options)
     ```
     */

    @objc
    public func track(_ eventName: String, properties: [String: Any], options: RSOption) {
        messageHandler.handleTrackEvent(eventName, properties: properties, options: options)
    }
    
    /**
     API for record screen
     - Parameters:
        - screenName: Name of the screen
     # Example #
     ```
     RSClient.sharedInstance().screen("MyViewController")
     ```
     */
    
    @objc
    public func screen(_ screenName: String) {
        messageHandler.handleScreenEvent(screenName)
    }
    
    /**
     API for record screen
     - Parameters:
        - screenName: Name of the screen
        - properties: Properties you want to pass with the screen call
     # Example #
     ```
     RSClient.sharedInstance().screen("MyViewController", properties: [:])
     ```
     */
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any]) {
        messageHandler.handleScreenEvent(screenName, properties: properties)
    }
    
    /**
     API for record screen
     - Parameters:
        - screenName: Name of the screen
        - properties: Properties you want to pass with the screen call
        - options: Options related to this screen call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().screen("MyViewController", properties: [:], options: options)
     ```
     */
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any], options: RSOption) {
        messageHandler.handleScreenEvent(screenName, properties: properties, options: options)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - groupId: Group ID you want your user to attach to
     # Example #
     ```
     RSClient.sharedInstance().group("A1")
     ```
     */
    
    @objc
    public func group(_ groupId: String) {
        messageHandler.handleGroupEvent(groupId)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - groupId: Group ID you want your user to attach to
        - traits: Traits of the group
     # Example #
     ```
     RSClient.sharedInstance().group("A1", traits: [:])
     ```
     */
    
    @objc
    public func group(_ groupId: String, traits: [String: Any]) {
        messageHandler.handleGroupEvent(groupId, traits: traits)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - groupId: Group ID you want your user to attach to
        - traits: Traits of the group
        - options: Options related to this group call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("A1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func group(_ groupId: String, traits: [String: Any], options: RSOption) {
        messageHandler.handleGroupEvent(groupId, traits: traits, options: options)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - newId: New userId for the user
     # Example #
     ```
     RSClient.sharedInstance().group("U1")
     ```
     */
    
    @objc
    public func alias(_ newId: String) {
        messageHandler.handleAlias(newId)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - newId: New userId for the user
        - options: Options related to this alias call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", options: options)
     ```
     */
    
    @objc
    public func alias(_ newId: String, options: RSOption) {
        messageHandler.handleAlias(newId, options: options)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - userId: User id of your user
     # Example #
     ```
     RSClient.sharedInstance().group("U1")
     ```
     */
    
    @objc
    public func identify(_ userId: String) {
        messageHandler.handleIdentify(userId)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - userId: User id of your user
        - traits: Other user properties
     # Example #
     ```
     RSClient.sharedInstance().group("U1", traits: [:])
     ```
     */
    
    @objc
    public func identify(_ userId: String, traits: [String: Any]) {
        messageHandler.handleIdentify(userId, traits: traits)
    }
    
    /**
     API for add the user to a group
     - Parameters:
        - userId: User id of your user
        - traits: Other user properties
        - options: Options related to this identify call
     # Example #
     ```
     let options = RSOption()
     RSClient.sharedInstance().group("U1", traits: [:], options: options)
     ```
     */
    
    @objc
    public func identify(_ userId: String, traits: [String: Any], options: RSOption) {
        messageHandler.handleIdentify(userId, traits: traits, options: options)
    }
    
    @objc
    public func getContext() -> RSContext? {
        guard !RSClient.getOptStatus() else {
            return nil
        }
        return eventManager.cachedContext
    }
    
    @objc
    public func reset() {
        eventManager.reset()
    }
    
    @objc
    public func flush() {
        guard !RSClient.getOptStatus() else {
            return
        }
        eventManager.flush()
    }
    
    @objc
    public static func putAnonymousId(_ anonymousId: String) {
        guard !RSClient.getOptStatus() else {
            return
        }
        RSUserDefaults.saveAnonymousId(anonymousId)
    }
    
    @objc
    public static func putDeviceToken(_ deviceToken: String) {
        guard !RSClient.getOptStatus() else {
            return
        }
        RSClient.shared.eventManager.cachedContext?.putDeviceToken(deviceToken)
    }
    
    @objc
    public func getAnonymousId() -> String? {
        guard !RSClient.getOptStatus() else {
            return nil
        }
        return RSUserDefaults.getAnonymousId()
    }
    
    @objc
    public func configuration() -> RSConfig? {
        guard !RSClient.getOptStatus() else {
            return nil
        }
        return eventManager.config
    }
    
    @objc
    public func trackLifecycleEvents(_ launchOptions: [AnyHashable: Any]?) {
        guard !RSClient.getOptStatus() else {
            return
        }
        (eventManager.appLifeCycleTrackingManager as? RSAppLifeCycleTrackingManager)?.applicationDidFinishLaunchingWithOptions(launchOptions)
    }
    
    @objc
    public func getDefaultOptions() -> RSOption? {
        guard !RSClient.getOptStatus() else {
            return nil
        }
        return eventManager.options
    }
    
    @objc
    public static func getOptStatus() -> Bool {
        if let optStatus = RSUserDefaults.getOptStatus() {
            logError("Opt out status: \(optStatus)")
            return optStatus
        }
        return false
    }
    
    @objc
    public func optOut(_ optOut: Bool) {
        RSUserDefaults.saveOptStatus(optOut)
    }
    
    @objc
    public func shutdown() {
        // TODO: decide shutdown behavior
    }
}
*/
