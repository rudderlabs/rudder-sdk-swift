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
    
    @objc internal(set) public var integrations: [String: Any]? {
        get { option.integrations }
        set { option.integrations = (newValue ?? [:]) + Constants.payload.integration }
    }
    
    @objc internal(set) public var customContext: [String: Any]? {
        get { option.customContext }
        set { option.customContext = newValue }
    }
    
    @objc internal(set) public var externalIds: [ObjCExternalId]? {
        get { option.externalIds?.compactMap { ObjCExternalId(externalId: $0) } }
        set { option.externalIds = newValue?.map { $0.externalId } }
    }
    
    override init() {
        self.option = RudderOption()
        super.init()
    }
}

@objc(RSOptionBuilder)
public final class ObjCOptionBuilder: NSObject {
    let option: ObjCOption
    
    @objc
    public override init() {
        self.option = ObjCOption()
        super.init()
    }
    
    @objc
    public func build() -> ObjCOption {
        return option
    }
    
    @objc
    @discardableResult
    public func setIntegrations(_ integrations: [String: Any]?) -> Self {
        self.option.integrations = integrations
        return self
    }
    
    @objc
    @discardableResult
    public func setCustomContext(_ customContext: [String: Any]?) -> Self {
        self.option.customContext = customContext
        return self
    }
    
    @objc
    @discardableResult
    public func setExternalIds(_ externalIds: [ObjCExternalId]?) -> Self {
        self.option.externalIds = externalIds
        return self
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
    
    public init(externalId: ExternalId) {
        self.externalId = externalId
        super.init()
    }
}
