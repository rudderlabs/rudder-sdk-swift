//
//  RSMessage.swift
//  Rudder
//
//  Created by Pallab Maiti on 05/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc open class RSMessage: NSObject {
    let messageId: String
    let channel: String
    var context: RSContext?
    var type: RSMessageType?
    var action: String?
    let originalTimestamp: String
    var anonymousId: String?
    var userId: String?
    var previousId: String?
    var groupId: String?
    var traits: [String: Any]?
    var event: String?
    var properties: [String: Any]?
    var userProperties: [String: Any]?
    var integrations: [String: Any]?
    var customContexts: [String: [String: Any]]?
    var destinationsProps: String?
    var option: RSOption?
    var isAll = false
    
    internal init(type: RSMessageType) {
        messageId = String(format: "%ld-%@", RSUtils.getTimeStamp(), RSUtils.getUniqueId())
        channel = "mobile"
        context = RSClient.shared.eventManager.cachedContext
        originalTimestamp = RSUtils.getTimestampString()
        anonymousId = RSUserDefaults.getAnonymousId()
        self.type = type
    }
    
    func toDict() -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["messageId"] = messageId
        dictionary["channel"] = channel
        var contextDict = context?.dict()
        if let customContexts = customContexts {
            for key in customContexts.keys {
                let dict = [key: customContexts]
                contextDict?[key] = dict
            }
        }
        dictionary["context"] = contextDict
        dictionary["type"] = type?.rawValue
        dictionary["action"] = action
        dictionary["originalTimestamp"] = originalTimestamp
        if let previousId = previousId {
            dictionary["previousId"] = previousId
        }
        if let traits = traits {
            dictionary["traits"] = traits
        }
        dictionary["anonymousId"] = anonymousId
        if let userId = userId {
            dictionary["userId"] = userId
        }
        if let properties = properties {
            dictionary["properties"] = properties
        }
        dictionary["event"] = event
        if let userProperties = userProperties {
            dictionary["userProperties"] = userProperties
        }
        dictionary["integrations"] = integrations
        return dictionary
    }
}
