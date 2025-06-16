//
//  ObjCConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

// MARK: - ObjCConfigurationBuilder
/**
 A builder class for configuring and constructing `Configuration` instances.
 */
@objc(RSAConfigurationBuilder)
public final class ObjCConfigurationBuilder: NSObject {
    
    private var writeKey: String
    private var dataPlaneUrl: String
    private var controlPlaneUrl: String = Constants.defaultConfig.controlPlaneUrl
    private var logLevel: LogLevel = Constants.log.defaultLevel
    private var gzipEnabled: Bool = Constants.defaultConfig.gzipEnabled
    private var flushPolicies: [ObjCFlushPolicy] = [ObjcStartupFlushPolicy(), ObjcCountFlushPolicy(), ObjcFrequencyFlushPolicy()]
    private var collectDeviceId: Bool = Constants.defaultConfig.willCollectDeviceId
    private var trackApplicationLifecycleEvents: Bool = Constants.defaultConfig.willTrackLifecycleEvents
    private var sessionConfiguration = SessionConfiguration()
    
    /**
     Initializes a new configuration builder with a write key and data plane URL.
     
     - Parameters:
     - writeKey: The write key for the configuration.
     - dataPlaneUrl: The URL to which events should be sent.
     */
    @objc
    public init(writeKey: String, dataPlaneUrl: String) {
        self.writeKey = writeKey
        self.dataPlaneUrl = dataPlaneUrl
        super.init()
    }
    
    /**
     Finalizes the configuration values and returns an `Configuration` instance.
     */
    @objc
    public func build() -> Configuration {
        let swiftFlushPolicies = flushPolicies.compactMap { objcPolicy in
            switch objcPolicy {
            case let policy as ObjcStartupFlushPolicy:
                return policy.flushPolicy as FlushPolicy
            case let policy as ObjcCountFlushPolicy:
                return policy.flushPolicy as FlushPolicy
            case let policy as ObjcFrequencyFlushPolicy:
                return policy.flushPolicy as FlushPolicy
            default:
                return nil as FlushPolicy?
            }
        }
        
        return Configuration(
            writeKey: writeKey,
            dataPlaneUrl: dataPlaneUrl,
            controlPlaneUrl: controlPlaneUrl,
            logLevel: logLevel,
            gzipEnaabled: gzipEnabled,
            flushPolicies: swiftFlushPolicies,
            collectDeviceId: collectDeviceId,
            trackApplicationLifecycleEvents: trackApplicationLifecycleEvents,
            sessionConfiguration: sessionConfiguration
        )
    }
    
    /** Sets the control plane URL. */
    @objc
    @discardableResult
    public func setControlPlaneUrl(_ controlPlaneUrl: String) -> Self {
        self.controlPlaneUrl = controlPlaneUrl
        return self
    }
    
    /** Sets the log level for the configuration. */
    @objc
    @discardableResult
    public func setLogLevel(_ logLevel: LogLevel) -> Self {
        self.logLevel = logLevel
        return self
    }
    
    /** Enables or disables gzip compression for the configuration. */
    @objc
    @discardableResult
    public func setGzipEnabled(_ gzipEnabled: Bool) -> Self {
        self.gzipEnabled = gzipEnabled
        return self
    }
    
    /** Sets the flush policies for the configuration. */
    @objc
    @discardableResult
    public func setFlushPolicies(_ policies: [ObjCFlushPolicy]) -> Self {
        self.flushPolicies = policies
        return self
    }
    
    /** Sets whether to collect the device ID. */
    @objc
    @discardableResult
    public func setCollectDeviceId(_ collectDeviceId: Bool) -> Self {
        self.collectDeviceId = collectDeviceId
        return self
    }
    
    /** Sets whether to track app lifecycle events automatically. */
    @objc
    @discardableResult
    public func setTrackApplicationLifecycleEvents(_ track: Bool) -> Self {
        self.trackApplicationLifecycleEvents = track
        return self
    }
    
    /** Sets the session configuration. */
    @objc
    @discardableResult
    public func setSessionConfiguration(_ configuration: SessionConfiguration) -> Self {
        self.sessionConfiguration = configuration
        return self
    }
}
