//
//  Types.swift
//  Segment
//
//  Created by Brandon Sneed on 12/1/20.
//

import Foundation

// MARK: - Event Types

protocol RSMessage {
    var type: RSMessageType { get set }
    var anonymousId: String? { get set }
    var messageId: String? { get set }
    var userId: String? { get set }
    var timestamp: String? { get set }
    var context: MessageContext? { get set }
    var integrations: MessageIntegrations? { get set }
    var option: RSOption? { get set }
    var channel: String? { get set }
    
    func toDict() -> [String: Any]
}

struct TrackMessage: RSMessage {
    var type: RSMessageType = .track
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var option: RSOption?
    var channel: String?
    
    var event: String?
    var properties: TrackProperties?

    func toDict() -> [String: Any] {
        var dictionary = staticDictionary()
        dynamicDictionary(dictionary: &dictionary)
        return dictionary
    }
    
    func dynamicDictionary(dictionary: inout [String: Any]) {
        dictionary["event"] = event
        dictionary["properties"] = properties
    }
    
    init(event: String, properties: TrackProperties?, option: RSOption? = nil) {
        self.event = event
        self.properties = properties
        self.option = option
    }
}

struct IdentifyMessage: RSMessage {
    var type: RSMessageType = .identify
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var option: RSOption?
    var channel: String?
    
    var traits: IdentifyTraits?
    
    func toDict() -> [String: Any] {
        var dictionary = staticDictionary()
        dynamicDictionary(dictionary: &dictionary)
        return dictionary
    }
    
    func dynamicDictionary(dictionary: inout [String: Any]) {
        dictionary[keyPath: "context.traits"] = traits
        dictionary["event"] = "identify"
    }
    
    init(userId: String? = nil, traits: IdentifyTraits? = nil, option: RSOption? = nil) {
        self.userId = userId
        self.traits = traits
        self.option = option
    }
}

struct ScreenMessage: RSMessage {
    var type: RSMessageType = .screen
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var option: RSOption?
    var channel: String?

    var name: String?
    var properties: MessageProperties?

    func toDict() -> [String: Any] {
        var dictionary = staticDictionary()
        dynamicDictionary(dictionary: &dictionary)
        return dictionary
    }
    
    func dynamicDictionary(dictionary: inout [String: Any]) {
        dictionary["properties"] = properties
        dictionary["event"] = name
    }
    
    init(title: String? = nil, properties: ScreenProperties? = nil, option: RSOption? = nil) {
        self.name = title
        self.properties = properties
        self.option = option
    }
}

struct GroupMessage: RSMessage {
    var type: RSMessageType = .group
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var option: RSOption?
    var channel: String?

    var groupId: String?
    var traits: GroupTraits?
    
    func toDict() -> [String: Any] {
        var dictionary = staticDictionary()
        dynamicDictionary(dictionary: &dictionary)
        return dictionary
    }
    
    func dynamicDictionary(dictionary: inout [String: Any]) {
        dictionary["traits"] = traits
        dictionary["groupId"] = groupId
    }
    
    init(groupId: String? = nil, traits: GroupTraits? = nil, option: RSOption? = nil) {
        self.groupId = groupId
        self.traits = traits
        self.option = option
    }
}

struct AliasMessage: RSMessage {
    var type: RSMessageType = .alias
    var anonymousId: String?
    var messageId: String?
    var userId: String?
    var timestamp: String?
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var option: RSOption?
    var channel: String?

    var previousId: String?
    
    func toDict() -> [String: Any] {
        var dictionary = staticDictionary()
        dynamicDictionary(dictionary: &dictionary)
        return dictionary
    }

    func dynamicDictionary(dictionary: inout [String: Any]) {
        dictionary["userId"] = userId
    }
    
    /*override var value: [String: Any] {
        var dictionary = super.value
        dictionary["previousId"] = previousId
        
//        var prevId: String?
//        prevId = traits?["userId"] as? String
//        if prevId == nil {
//            prevId = traits?["id"] as? String
//        }
//
//        if prevId != nil {
//            message.previousId = prevId
//        }
//        traits?["id"] = newId
//        traits?["userId"] = newId
//
//        if let traits = traits {
//            dictionary["traits"] = traits
//        }
        return dictionary
    }*/
    
    init(newId: String? = nil, option: RSOption? = nil) {
        self.userId = newId
        self.option = option
    }
    
    init(existing: AliasMessage) {
        self.init(newId: existing.userId)
        applyRawEventData(event: existing)
    }
}

// MARK: - RawEvent conveniences

internal struct IntegrationConstants {
    static let allIntegrationsKey = "All"
}

extension RSMessage {
    /**
     Disable all cloud-mode integrations for this event, except for any specific keys given.
     This will preserve any per-integration specific settings if the integration is to remain enabled.
     - Parameters:
        - exceptKeys: A list of integration keys to exclude from disabling.
     */
    func disableCloudIntegrations(exceptKeys: [String]? = nil) {
        /*guard let existing = integrations?.dictionaryValue else {
            // this shouldn't happen, might oughta log it.
            Analytics.segmentLog(message: "Unable to get what should be a valid list of integrations from event.", kind: .error)
            return
        }
        var new = [String: Any]()
        new[IntegrationConstants.allIntegrationsKey] = false
        if let exceptKeys = exceptKeys {
            for key in exceptKeys {
                if let value = existing[key], value is [String: Any] {
                    new[key] = value
                } else {
                    new[key] = true
                }
            }
        }
        
        do {
            integrations = try JSON(new)
        } catch {
            // this shouldn't happen, log it.
            Analytics.segmentLog(message: "Unable to convert list of integrations to JSON. \(error)", kind: .error)
        }*/
    }
    
    /**
     Enable all cloud-mode integrations for this event, except for any specific keys given.
     - Parameters:
        - exceptKeys: A list of integration keys to exclude from enabling.
     */
    func enableCloudIntegrations(exceptKeys: [String]? = nil) {
        /*var new = [String: Any]()
        new[IntegrationConstants.allIntegrationsKey] = true
        if let exceptKeys = exceptKeys {
            for key in exceptKeys {
                new[key] = false
            }
        }
        
        do {
            integrations = try JSON(new)
        } catch {
            // this shouldn't happen, log it.
            Analytics.segmentLog(message: "Unable to convert list of integrations to JSON. \(error)", kind: .error)
        }*/
    }
    
    /**
     Disable a specific cloud-mode integration using it's key name.
     - Parameters:
        - key: The key name of the integration to disable.
     */
    func disableIntegration(key: String) {
        /*guard let existing = integrations?.dictionaryValue else {
            // this shouldn't happen, might oughta log it.
            Analytics.segmentLog(message: "Unable to get what should be a valid list of integrations from event.", kind: .error)
            return
        }
        // we don't really care what the value of this key was before, as
        // a disabled one can only be false.
        var new = existing
        new[key] = false
        
        do {
            integrations = try JSON(new)
        } catch {
            // this shouldn't happen, log it.
            Analytics.segmentLog(message: "Unable to convert list of integrations to JSON. \(error)", kind: .error)
        }*/
    }
    
    /**
     Enable a specific cloud-mode integration using it's key name.
     - Parameters:
        - key: The key name of the integration to enable.
     */
    func enableIntegration(key: String) {
        /*guard let existing = integrations?.dictionaryValue else {
            // this shouldn't happen, might oughta log it.
            Analytics.segmentLog(message: "Unable to get what should be a valid list of integrations from event.", kind: .error)
            return
        }
        
        var new = existing
        // if it's a dictionary already, it's considered enabled, so don't
        // overwrite whatever they may have put there.  If that's not the case
        // just set it to true since that's the only other value it could have
        // to be considered `enabled`.
        if (existing[key] as? [String: Any]) == nil {
            new[key] = true
        }
        
        do {
            integrations = try JSON(new)
        } catch {
            // this shouldn't happen, log it.
            Analytics.segmentLog(message: "Unable to convert list of integrations to JSON. \(error)", kind: .error)
        }*/
    }
    
}


// MARK: - RawEvent data helpers

extension RSMessage {
    internal mutating func applyRawEventData(event: RSMessage?) {
        if let e = event {
            anonymousId = e.anonymousId
            messageId = e.messageId
            userId = e.userId
            timestamp = e.timestamp
            context = e.context
            integrations = e.integrations
        }
    }

    internal func applyRawEventData() -> Self {
        var result: Self = self
                
        result.anonymousId = RSUserDefaults.getAnonymousId()
//        result.userId = RSUserDefaults
        result.messageId = String(format: "%ld-%@", RSUtils.getTimeStamp(), RSUtils.getUniqueId())
        result.timestamp = RSUtils.getTimestampString()
        result.channel = "mobile"
//        result.context = Context
//        result.integrations = try? JSON([String: Any]())
        
        return result
    }
    
    func staticDictionary() -> [String: Any] {
        return ["messageId": messageId ?? "",
                "anonymousId": anonymousId ?? "",
                "channel": channel ?? "",
                "originalTimestamp": timestamp ?? "",
                "type": type.rawValue]
        // integrations
    }
}
