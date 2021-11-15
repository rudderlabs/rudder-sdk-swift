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
    public static func setAnonymousId(_ anonymousId: String) {
        RSUserDefaults.saveAnonymousId(anonymousId)
    }
    
    @objc
    public func track(_ eventName: String) {
        let message = RSMessage(type: .track)
        message.event = eventName
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func track(_ eventName: String, properties: [String: Any]) {
        let message = RSMessage(type: .track)
        message.event = eventName
        message.properties = properties
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func track(_ eventName: String, properties: [String: Any], options: RSOption) {
        let message = RSMessage(type: .track)
        message.event = eventName
        message.properties = properties
        message.option = options
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func screen(_ screenName: String) {
        let message = RSMessage(type: .screen)
        message.event = screenName
        let properties = ["name": screenName]
        message.properties = properties
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any]) {
        let message = RSMessage(type: .screen)
        message.event = screenName
        var properties = properties
        properties["name"] = screenName
        message.properties = properties
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func screen(_ screenName: String, properties: [String: Any], options: RSOption) {
        let message = RSMessage(type: .screen)
        message.event = screenName
        var properties = properties
        properties["name"] = screenName
        message.properties = properties
        message.option = options
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func group(_ groupId: String) {
        let message = RSMessage(type: .group)
        message.groupId = groupId
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func group(_ groupId: String, traits: [String: Any]) {
        let message = RSMessage(type: .group)
        message.groupId = groupId
        message.traits = traits
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func group(_ groupId: String, traits: [String: Any], options: RSOption) {
        let message = RSMessage(type: .group)
        message.groupId = groupId
        message.traits = traits
        message.option = options
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func alias(_ newId: String) {
        alias(newId, options: nil)
    }
    
    @objc
    public func alias(_ newId: String, options: RSOption?) {
        let message = RSMessage(type: .alias)
        message.userId = newId
        message.option = options
        let context = RSClient.shared.eventManager.cachedContext
        var traits = context?.traits
        var prevId: String?
        prevId = traits?["userId"] as? String
        if prevId == nil {
            prevId = traits?["id"] as? String
        }
        
        if prevId != nil {
            message.previousId = prevId
        }
        traits?["id"] = newId
        traits?["userId"] = newId
        
        RSClient.shared.eventManager.cachedContext?.traits = traits
        RSClient.shared.eventManager.cachedContext?.saveTraits()
        message.traits = traits
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func identify(_ userId: String) {
        let traitsCopy = RSTraits()
        traitsCopy.userId = userId
        let message = RSMessage(type: .identify)
        message.event = RSMessageType.identify.rawValue
        message.userId = userId
        RSClient.shared.eventManager.cachedContext?.updateTraits(traitsCopy)
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func identify(_ userId: String, traits: [String: Any]) {
        let traitsCopy = RSTraits(dict: traits)
        traitsCopy.userId = userId
        let message = RSMessage(type: .identify)
        message.event = RSMessageType.identify.rawValue
        message.userId = userId
        RSClient.shared.eventManager.cachedContext?.updateTraits(traitsCopy)
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func identify(_ userId: String, traits: [String: Any], options: RSOption) {
        let traitsCopy = RSTraits(dict: traits)
        traitsCopy.userId = userId
        let message = RSMessage(type: .identify)
        message.event = RSMessageType.identify.rawValue
        message.userId = userId
        message.option = options
        RSClient.shared.eventManager.cachedContext?.updateTraits(traitsCopy)
        messageHandler.dumpMessage(message)
    }
    
    @objc
    public func getContext() -> RSContext? {
        return eventManager.cachedContext
    }
    
    @objc
    public func reset() {
        
    }
    
    /*
     - (void)reset {
         [RSElementCache reset];
         if (_repository != nil) {
             [_repository reset];
         }
     }

     - (NSString*)getAnonymousId {
         // returns anonymousId
         return [RSElementCache getContext].device.identifier;
     }


     - (RSConfig*)configuration {
         if (_repository == nil) {
             return nil;
         }
         return [_repository getConfig];
     }

     - (void)trackLifecycleEvents:(NSDictionary *)launchOptions {
         [_repository _applicationDidFinishLaunchingWithOptions:launchOptions];
     }

     + (instancetype)sharedInstance {
         return _instance;
     }

     + (RSOption*) getDefaultOptions {
         return _defaultOptions;
     }
     + (void)setAnonymousId:(NSString *)anonymousId {
         RSPreferenceManager *preferenceManager = [RSPreferenceManager getInstance];
         [preferenceManager saveAnonymousId:anonymousId];
     }
     */
}
