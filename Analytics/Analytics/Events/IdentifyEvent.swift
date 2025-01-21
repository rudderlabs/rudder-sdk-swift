//
//  IdentifyEvent.swift
//  Analytics
//
//  Created by Satheesh Kannan on 21/01/25.
//

import Foundation

struct IdentifyEvent: Message {
    
    var type: EventType = .identify
    
    var messageId: String = .randomUUIDString
    
    var originalTimeStamp: String = .currentTimeStamp
    
    var anonymousId: String?
    
    var channel: String?
    
    var integrations: [String : Bool]?
    
    var sentAt: String?
    
    var context: [String : AnyCodable]?
    
    var traits: CodableCollection?
    
    var userId: String?
    
    init(traits: RudderTraits? = nil, options: RudderOptions? = nil, userIdentity: UserIdentity = UserIdentity()) {
        self.userId = userIdentity.userId
        self.integrations = options == nil ? Constants.defaultIntegration : options?.integrations
        
        self.context = options?.customContext?.isEmpty == false ?
        options?.customContext?.compactMapValues { AnyCodable($0) } : nil
        
        self.anonymousId = userIdentity.anonymousId
        self.addDefaultValues()
    }
}
