//
//  Types.swift
//  Segment
//
//  Created by Brandon Sneed on 12/1/20.
//

import Foundation

// MARK: - Event Types

protocol Message {
    var type: RSMessageType { get set }
    var anonymousId: String? { get set }
    var messageId: String { get set }
    var userId: String? { get set }
    var timestamp: String { get set }
    var context: MessageContext? { get set }
    var integrations: MessageIntegrations? { get set }
    var properties: MessageProperties? { get set }
    var option: RSOption? { get set }
    var channel: String { get set }
    
    func toDict() -> [String: Any]
}

/*class Message {
    var type: RSMessageType?
    var anonymousId: String? = RSUserDefaults.getAnonymousId()
    var messageId: String = String(format: "%ld-%@", RSUtils.getTimeStamp(), RSUtils.getUniqueId())
    var userId: String?
    var timestamp: String = RSUtils.getTimestampString()
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var properties: MessageProperties? = nil
    var option: RSOption?
    var channel: String = "mobile"

    var value: [String: Any] {
        var dictionary = [String: Any]()
        dictionary["messageId"] = messageId
        dictionary["anonymousId"] = anonymousId
        dictionary["type"] = type?.rawValue
        dictionary["originalTimestamp"] = timestamp
        dictionary["channel"] = channel
        if let userId = userId {
            dictionary["userId"] = userId
        }
        dictionary["integrations"] = integrations
        dictionary["context"] = context
        return dictionary
    }
//    var metrics: [JSON]? { get set }
    
    init() {

    }
}*/

struct TrackMessage: Message {
    var type: RSMessageType = .track
    var anonymousId: String? = RSUserDefaults.getAnonymousId()
    var messageId: String = String(format: "%ld-%@", RSUtils.getTimeStamp(), RSUtils.getUniqueId())
    var userId: String?
    var timestamp: String = RSUtils.getTimestampString()
    var context: MessageContext?
    var integrations: MessageIntegrations?
    var properties: MessageProperties?
    var option: RSOption?
    var channel: String = "mobile"
    var event: String

    func toDict() -> [String : Any] {
        return [String: Any]()
    }
    
    init(event: String, properties: MessageProperties?, option: RSOption? = nil) {
        self.event = event
        self.properties = properties
        self.option = option
        self.type = .track
    }
}

class TrackMessage: Message {
    var event: String
    
    override var value: [String: Any] {
//        set {
//            var dictionary = [String: Any]()
//            dictionary["messageId"] = messageId
//            dictionary["channel"] = channel
//            var contextDict = context
//            if let customContexts = customContexts {
//                for key in customContexts.keys {
//                    let dict = [key: customContexts]
//                    contextDict?[key] = dict
//                }
//            }
//            dictionary["context"] = contextDict
//            dictionary["type"] = type?.rawValue
//            dictionary["action"] = action
//            dictionary["originalTimestamp"] = timestamp
//            dictionary["anonymousId"] = anonymousId
//            if let userId = userId {
//                dictionary["userId"] = userId
//            }
//            if let properties = properties {
//                dictionary["properties"] = properties
//            }
//            dictionary["event"] = event
//            if let userProperties = userProperties {
//                dictionary["userProperties"] = userProperties
//            }
//            dictionary["integrations"] = integrations
//            super.value = dictionary
//        }
        var dictionary = super.value
        dictionary["event"] = event
        return dictionary
    }
    
    init(event: String, properties: MessageProperties?, option: RSOption? = nil) {
        self.event = event
        self.properties = properties
        self.option = option
        self.type = .track
    }
}

class IdentifyMessage: Message {
    
    var traits: IdentifyTraits?
    
    override var value: [String: Any] {
        var dictionary = super.value
        dictionary["event"] = "identify"
        return dictionary
    }
    
    init(userId: String? = nil, traits: IdentifyTraits? = nil, option: RSOption? = nil) {
        self.userId = userId
        self.traits = traits
        self.option = option
        self.type = .identify
    }
}

class ScreenMessage: Message {
    
    var name: String?
    
    override var value: [String: Any] {
        var dictionary = super.value
        dictionary["event"] = name
        return dictionary
    }
    
    init(title: String? = nil, properties: MessageProperties? = nil, option: RSOption? = nil) {
        self.name = title
        self.properties = properties
        self.option = option
        self.type = .identify
    }
}

class GroupMessage: Message {
    var groupId: String?
    var traits: GroupTraits?
    
    override var value: [String: Any] {
        var dictionary = super.value
        dictionary["groupId"] = groupId
        return dictionary
    }
    
    init(groupId: String? = nil, traits: GroupTraits? = nil, option: RSOption? = nil) {
        self.groupId = groupId
        self.traits = traits
        self.option = option
        self.type = .group
    }
}

class AliasMessage: Message {
    var previousId: String?
    
    override var value: [String: Any] {
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
    }
    
    init(newId: String? = nil, option: RSOption? = nil) {
        self.userId = newId
        self.option = option
        self.type = .alias
    }
    
//    init(existing: AliasMessage) {
//        self.init(newId: existing.userId)
//        applyRawEventData(event: existing)
//    }
}

// MARK: - RawEvent conveniences

internal struct IntegrationConstants {
    static let allIntegrationsKey = "All"
}

extension Message {
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

extension Message {
    /*internal func applyRawEventData(event: Message?) {
        if let e = event {
            anonymousId = e.anonymousId
            messageId = e.messageId
            userId = e.userId
            timestamp = e.timestamp
            context = e.context
            integrations = e.integrations
        }
    }

    internal func applyRawEventData(store: Store) -> Self {
        var result: Self = self
        
        guard let userInfo: UserInfo = store.currentState() else { return self }
        
        result.anonymousId = userInfo.anonymousId
        result.userId = userInfo.userId
        result.messageId = UUID().uuidString
        result.timestamp = Date().iso8601()
        result.integrations = try? JSON([String: Any]())
        
        return result
    }*/
}
