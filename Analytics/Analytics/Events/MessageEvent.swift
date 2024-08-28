//
//  MessageEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 20/08/24.
//

import Foundation

public typealias RudderOptions = [String: Any]
public typealias RudderProperties = [String: Any]

@objc
public enum EventType: Int {
    case track, screen, alias, identify, group
    
    public var title: String {
        return String(describing: self).capitalized
    }
}

@objcMembers
public class MessageEvent {
    public var type: EventType
    public var messageId: String
    public var originalTimeStamp: String
    
    init(type: EventType, messageId: String, originalTimeStamp: String) {
        self.type = type
        self.messageId = messageId
        self.originalTimeStamp = originalTimeStamp
    }
}

@objcMembers
public class TrackEvent: MessageEvent {
    
    var event: String
    var properties: RudderProperties
    var options: RudderOptions
    
    init(event: String, properties: RudderProperties, options: RudderOptions,
         type: EventType = .track, messageId: String = .randomUUIDString, originalTimeStamp: String = .currentTimeStamp) {
        self.event = event
        self.properties = properties
        self.options = options
        
        super.init(type: type, messageId: messageId, originalTimeStamp: originalTimeStamp)
    }
}
