//
//  ObjCConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

@objc(RSConfiguration)
public class ObjCConfiguration: NSObject {
    
    let configuration: Configuration
    
    @objc internal(set) public var writeKey: String {
        get { configuration.writeKey }
        set { configuration.writeKey = newValue }
    }
    
    @objc internal(set) public var dataPlaneUrl: String {
        get { configuration.dataPlaneUrl }
        set { configuration.dataPlaneUrl = newValue }
    }
    
    @objc internal(set) public var controlPlaneUrl: String {
        get { return configuration.controlPlaneUrl}
        set { configuration.controlPlaneUrl = newValue }
    }
    
    @objc internal(set) public var logLevel: LogLevel {
        get { return configuration.logLevel }
        set { configuration.logLevel = newValue }
    }
    
    @objc internal(set) public var optOut: Bool {
        get { configuration.optOut }
        set { configuration.optOut = newValue }
    }
    
    @objc internal(set) public var gzipEnabled: Bool {
        get { configuration.gzipEnabled }
        set { configuration.gzipEnabled = newValue }
    }
    
    @objc internal(set) public var collectDeviceId: Bool {
        get { configuration.collectDeviceId }
        set { configuration.collectDeviceId = newValue }
    }
    
    @objc internal(set) public var trackApplicationLifecycleEvents: Bool {
        get { configuration.trackApplicationLifecycleEvents }
        set { configuration.trackApplicationLifecycleEvents = newValue }
    }
    
    var flushPolicies: [FlushPolicy] {
        return configuration.flushPolicies
    }
    
    var sessionConfiguration: SessionConfiguration {
        return configuration.sessionConfiguration
    }
    
    init(writeKey: String, dataPlaneUrl: String) {
        self.configuration = Configuration(writeKey: writeKey, dataPlaneUrl: dataPlaneUrl)
    }
}

@objc(RSConfigurationBuilder)
public class ObjCConfigurationBuilder: NSObject {
    
    let configuration: ObjCConfiguration
    
    @objc
    public init(writeKey: String, dataPlaneUrl: String) {
        self.configuration = ObjCConfiguration(writeKey: writeKey, dataPlaneUrl: dataPlaneUrl)
        super.init()
    }
    
    @objc
    public func build() -> ObjCConfiguration {
        return configuration
    }
    
    @objc
    @discardableResult
    public func setControlPlaneUrl(_ controlPlaneUrl: String) -> Self {
        self.configuration.controlPlaneUrl = controlPlaneUrl
        return self
    }
    
    @objc
    @discardableResult
    public func setLogLevel(_ logLevel: LogLevel) -> Self {
        self.configuration.logLevel = logLevel
        return self
    }
    
    @objc
    @discardableResult
    public func setOptOut(_ optOut: Bool) -> Self {
        self.configuration.optOut = optOut
        return self
    }
    
    @objc
    @discardableResult
    public func setGzipEnabled(_ gzipEnabled: Bool) -> Self {
        self.configuration.gzipEnabled = gzipEnabled
        return self
    }
    
    @objc
    @discardableResult
    public func setCollectDeviceId(_ collectDeviceId: Bool) -> Self {
        self.configuration.collectDeviceId = collectDeviceId
        return self
    }
    
    @objc
    @discardableResult
    public func setTrackApplicationLifecycleEvents(_ track: Bool) -> Self {
        self.configuration.trackApplicationLifecycleEvents = track
        return self
    }
}
