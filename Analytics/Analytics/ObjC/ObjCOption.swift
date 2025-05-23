//
//  ObjCOption.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

@objc(RSOption)
public final class ObjCOption: NSObject {
    let option: RudderOption
    
    @objc
    public init(integrations: [String: Any]?, customContext: [String: Any]?, externalIds: [ObjCExternalId]?) {
        let externalIdValues = externalIds?.map { $0.externalId }
        self.option = RudderOption(integrations: integrations, customContext: customContext, externalIds: externalIdValues)
        super.init()
    }
    
    @objc
    public convenience override init() {
        self.init(integrations: nil, customContext: nil, externalIds: nil)
    }
    
    @objc
    public convenience init(integrations: [String: Any]?) {
        self.init(integrations: integrations, customContext: nil, externalIds: nil)
    }
    
    @objc
    public convenience init(customContext: [String: Any]?) {
        self.init(integrations: nil, customContext: customContext, externalIds: nil)
    }
    
    @objc
    public convenience init(externalIds: [ObjCExternalId]?) {
        self.init(integrations: nil, customContext: nil, externalIds: externalIds)
    }
    
    @objc
    public convenience init(integrations: [String: Any]?, customContext: [String: Any]?) {
        self.init(integrations: integrations, customContext: customContext, externalIds: nil)
    }
    
    @objc
    public convenience init(customContext: [String: Any]?, externalIds: [ObjCExternalId]?) {
        self.init(integrations: nil, customContext: customContext, externalIds: externalIds)
    }
    
    @objc
    public convenience init(integrations: [String: Any]?, externalIds: [ObjCExternalId]?) {
        self.init(integrations: integrations, customContext: nil, externalIds: externalIds)
    }
}

@objc(RSExternalId)
public final class ObjCExternalId: NSObject {
    let externalId: ExternalId
    
    @objc
    public init(type: String, id: String) {
        self.externalId = ExternalId(type: type, id: id)
        super.init()
    }
}
