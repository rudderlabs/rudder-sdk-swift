//
//  RSClient.swift
//  Rudder
//
//  Created by Pallab Maiti on 04/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc open class RSClient: NSObject {
    internal static let shared = RSClient()
    internal let eventManager = RSEventManager()
    internal let logger = RSLogger()
    internal let messageHandler = RSMessageHandler()

    private override init() {
        
    }
    
    @objc
    public static func sharedInstance() -> RSClient {
        return shared
    }
    
    @objc
    public static func getInstance(_ writeKey: String) {
        getInstance(writeKey, config: RSConfig(), options: RSOption())
    }
    
    @objc
    public static func getInstance(_ writeKey: String, config: RSConfig) {
        getInstance(writeKey, config: config, options: RSOption())
    }
    
    @objc
    public static func getInstance(_ writeKey: String, config: RSConfig, options: RSOption) {
        RSClient.shared.eventManager.configure(writeKey: writeKey, config: config, options: options)
    }
    
    @objc
    public func track(_ eventName: String) {
        messageHandler.handleTrackEvent(eventName)
    }
    
    @objc
    public func track(_ eventName: String, properties: [String: Any]) {
        messageHandler.handleTrackEvent(eventName, properties: properties)
    }
    
    @objc
    public func track(_ eventName: String, properties: [String: Any], options: RSOption) {
        messageHandler.handleTrackEvent(eventName, properties: properties, options: options)
    }
    
    @objc
    public func screen(_ screenName: String) {
        messageHandler.handleScreenEvent(screenName)
    }
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any]) {
        messageHandler.handleScreenEvent(screenName, properties: properties)
    }
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any], options: RSOption) {
        messageHandler.handleScreenEvent(screenName, properties: properties, options: options)
    }
    
    @objc
    public func group(_ groupId: String) {
        messageHandler.handleGroupEvent(groupId)
    }
    
    @objc
    public func group(_ groupId: String, traits: [String: Any]) {
        messageHandler.handleGroupEvent(groupId, traits: traits)
    }
    
    @objc
    public func group(_ groupId: String, traits: [String: Any], options: RSOption) {
        messageHandler.handleGroupEvent(groupId, traits: traits, options: options)
    }
    
    @objc
    public func alias(_ newId: String) {
        messageHandler.handleAlias(newId)
    }
    
    @objc
    public func alias(_ newId: String, options: RSOption) {
        messageHandler.handleAlias(newId, options: options)
    }
    
    @objc
    public func identify(_ userId: String) {
        messageHandler.handleIdentify(userId)
    }
    
    @objc
    public func identify(_ userId: String, traits: [String: Any]) {
        messageHandler.handleIdentify(userId, traits: traits)
    }
    
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
    public static func setAnonymousId(_ anonymousId: String) {
        guard !RSClient.getOptStatus() else {
            return
        }
        RSUserDefaults.saveAnonymousId(anonymousId)
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
