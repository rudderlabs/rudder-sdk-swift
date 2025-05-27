//
//  ObjCConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

// MARK: - ObjCConfiguration
/**
 A wrapper class that exposes the Swift `Configuration` to Objective-C.
 */
@objc(RSConfiguration)
public final class ObjCConfiguration: NSObject {

    let configuration: Configuration

    /** The write key used to identify the project. */
    @objc internal(set) public var writeKey: String {
        get { configuration.writeKey }
        set { configuration.writeKey = newValue }
    }

    /** The URL of the data plane where events are sent. */
    @objc internal(set) public var dataPlaneUrl: String {
        get { configuration.dataPlaneUrl }
        set { configuration.dataPlaneUrl = newValue }
    }

    /** The URL of the control plane for fetching configuration. */
    @objc internal(set) public var controlPlaneUrl: String {
        get { return configuration.controlPlaneUrl }
        set { configuration.controlPlaneUrl = newValue }
    }

    /** The logging level used by the SDK. */
    @objc internal(set) public var logLevel: LogLevel {
        get { return configuration.logLevel }
        set { configuration.logLevel = newValue }
    }

    /** Flag to indicate whether the SDK is opted out of tracking. */
    @objc internal(set) public var optOut: Bool {
        get { configuration.optOut }
        set { configuration.optOut = newValue }
    }

    /** Flag to enable or disable gzip compression for events. */
    @objc internal(set) public var gzipEnabled: Bool {
        get { configuration.gzipEnabled }
        set { configuration.gzipEnabled = newValue }
    }

    /** Determines how events are stored before being flushed. */
    @objc internal(set) public var storageMode: StorageMode {
        get { return configuration.storageMode }
        set { configuration.storageMode = newValue }
    }

    /** The flush policies applied to control when events are sent. */
    @objc internal(set) public var flushPolicies: [ObjCFlushPolicy] {
        get {
            return configuration.flushPolicies.compactMap {
                return switch $0 {
                case let policy as StartupFlushPolicy:
                    ObjcStartupFlushPolicy(policy: policy)
                case let policy as CountFlushPolicy:
                    ObjcCountFlushPolicy(policy: policy)
                case let policy as FrequencyFlushPolicy:
                    ObjcFrequencyFlushPolicy(policy: policy)
                default:
                    nil
                }
            }
        }
        set {
            configuration.flushPolicies = newValue.compactMap { objcPolicy in
                switch objcPolicy {
                case let policy as ObjcStartupFlushPolicy:
                    return policy.flushPolicy
                case let policy as ObjcCountFlushPolicy:
                    return policy.flushPolicy
                case let policy as ObjcFrequencyFlushPolicy:
                    return policy.flushPolicy
                default:
                    return nil
                }
            }
        }
    }

    /** Whether to collect the device identifier. */
    @objc internal(set) public var collectDeviceId: Bool {
        get { configuration.collectDeviceId }
        set { configuration.collectDeviceId = newValue }
    }

    /** Whether to track application lifecycle events automatically. */
    @objc internal(set) public var trackApplicationLifecycleEvents: Bool {
        get { configuration.trackApplicationLifecycleEvents }
        set { configuration.trackApplicationLifecycleEvents = newValue }
    }

    /** The session-related configuration used for tracking sessions. */
    @objc internal(set) public var sessionConfiguration: ObjCSessionConfiguration {
        get { ObjCSessionConfiguration(configuration: configuration.sessionConfiguration) }
        set { configuration.sessionConfiguration = newValue.configuration }
    }

    /**
     Initializes a new configuration with the provided write key and data plane URL.

     - Parameters:
       - writeKey: The project's write key.
       - dataPlaneUrl: The URL to which events should be sent.
     */
    init(writeKey: String, dataPlaneUrl: String) {
        self.configuration = Configuration(writeKey: writeKey, dataPlaneUrl: dataPlaneUrl)
        super.init()
    }
}

// MARK: - ObjCConfigurationBuilder
/**
 A builder class for configuring and constructing `ObjCConfiguration` instances.
 */
@objc(RSConfigurationBuilder)
public final class ObjCConfigurationBuilder: NSObject {

    let configuration: ObjCConfiguration

    /**
     Initializes a new configuration builder with a write key and data plane URL.

     - Parameters:
       - writeKey: The write key for the configuration.
       - dataPlaneUrl: The URL to which events should be sent.
     */
    @objc
    public init(writeKey: String, dataPlaneUrl: String) {
        self.configuration = ObjCConfiguration(writeKey: writeKey, dataPlaneUrl: dataPlaneUrl)
        super.init()
    }

    /**
     Finalizes the configuration and returns an `ObjCConfiguration` instance.
     */
    @objc
    public func build() -> ObjCConfiguration {
        return configuration
    }

    /** Sets the control plane URL. */
    @objc
    @discardableResult
    public func setControlPlaneUrl(_ controlPlaneUrl: String) -> Self {
        self.configuration.controlPlaneUrl = controlPlaneUrl
        return self
    }

    /** Sets the log level for the configuration. */
    @objc
    @discardableResult
    public func setLogLevel(_ logLevel: LogLevel) -> Self {
        self.configuration.logLevel = logLevel
        return self
    }

    /** Sets the opt-out flag for the configuration. */
    @objc
    @discardableResult
    public func setOptOut(_ optOut: Bool) -> Self {
        self.configuration.optOut = optOut
        return self
    }

    /** Enables or disables gzip compression for the configuration. */
    @objc
    @discardableResult
    public func setGzipEnabled(_ gzipEnabled: Bool) -> Self {
        self.configuration.gzipEnabled = gzipEnabled
        return self
    }

    /** Sets the storage mode for the configuration. */
    @objc
    @discardableResult
    public func setStorageMode(_ storageMode: StorageMode) -> Self {
        self.configuration.storageMode = storageMode
        return self
    }

    /** Sets the flush policies for the configuration. */
    @objc
    @discardableResult
    public func setFlushPolicies(_ policies: [ObjCFlushPolicy]) -> Self {
        self.configuration.flushPolicies = policies
        return self
    }

    /** Sets whether to collect the device ID. */
    @objc
    @discardableResult
    public func setCollectDeviceId(_ collectDeviceId: Bool) -> Self {
        self.configuration.collectDeviceId = collectDeviceId
        return self
    }

    /** Sets whether to track app lifecycle events automatically. */
    @objc
    @discardableResult
    public func setTrackApplicationLifecycleEvents(_ track: Bool) -> Self {
        self.configuration.trackApplicationLifecycleEvents = track
        return self
    }

    /** Sets the session configuration. */
    @objc
    @discardableResult
    public func setSessionConfiguration(_ configuration: ObjCSessionConfiguration) -> Self {
        self.configuration.sessionConfiguration = configuration
        return self
    }
}
