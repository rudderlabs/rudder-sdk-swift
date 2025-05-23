//
//  ObjCSessionConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

@objc(RSSessionConfiguration)
public final class ObjCSessionConfiguration: NSObject {
    
    let configuration: SessionConfiguration
    
    @objc internal(set) public var automaticSessionTracking: Bool {
        get { configuration.automaticSessionTracking }
        set { configuration.automaticSessionTracking = newValue }
    }
    
    @objc internal(set) public var sessionTimeoutInMillis: UInt64 {
        get { configuration.sessionTimeoutInMillis }
        set { configuration.sessionTimeoutInMillis = newValue }
    }
    
    override init() {
        self.configuration = SessionConfiguration()
        super.init()
    }
    
    public init(configuration: SessionConfiguration) {
        self.configuration = configuration
        super.init()
    }
}

@objc(RSSessionConfigurationBuilder)
public final class ObjCSessionConfigurationBuilder: NSObject {
    
    let configuration: ObjCSessionConfiguration
    
    @objc
    public override init() {
        configuration = ObjCSessionConfiguration()
        super.init()
    }
    
    @objc
    public func build() -> ObjCSessionConfiguration {
        return configuration
    }
    
    @objc
    @discardableResult
    public func setAutomaticSessionTracking(_ track: Bool) -> Self {
        self.configuration.automaticSessionTracking = track
        return self
    }
    
    @objc
    @discardableResult
    public func setSessionTimeoutInMillis(_ timeoutInMillis: NSNumber) -> Self {
        if timeoutInMillis.int64Value > 0 {
            self.configuration.sessionTimeoutInMillis = timeoutInMillis.uint64Value
        }
        return self
    }
}
