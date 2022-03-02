//
//  RSMessage.swift
//  Rudder
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

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
        dictionary["userId"] = userId
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
        dictionary["userId"] = userId
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
        dictionary["userId"] = userId
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
        dictionary["userId"] = userId
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
        dictionary["previousId"] = previousId
    }
        
    init(newId: String? = nil, option: RSOption? = nil) {
        self.userId = newId
        self.option = option
    }
    
    init(existing: AliasMessage) {
        self.init(newId: existing.userId)
        applyRawEventData(event: existing)
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
        result.messageId = String(format: "%ld-%@", RSUtils.getTimeStamp(), RSUtils.getUniqueId())
        result.timestamp = RSUtils.getTimestampString()
        result.channel = "mobile"
        return result
    }
    
    func staticDictionary() -> [String: Any] {
        var dict = ["messageId": messageId ?? "",
                    "anonymousId": anonymousId ?? "",
                    "channel": channel ?? "",
                    "originalTimestamp": timestamp ?? "",
                    "type": type.rawValue] as [String: Any]
        if let context = context {
            dict["context"] = context
        }
        if let integrations = integrations {
            dict["integrations"] = integrations
        }
        return dict
    }
}
