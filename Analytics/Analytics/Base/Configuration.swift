//
//  Configuration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import Foundation

// MARK: - Configuration
/**
 The `Configuration` class represents the settings used to initialize and configure the Analytics SDK. It provides customization for key parameters like URLs, logging behavior, and data collection preferences.
 */
@objcMembers
public class Configuration {

    /**
     The write key used to authenticate with the analytics service.
     */
    var writeKey: String

    /**
     The URL for the data plane where analytics events are sent.
     */
    var dataPlaneUrl: String

    /**
     The URL for the control plane to fetch configuration data.
     */
    var controlPlaneUrl: String

    /**
     The logger instance used for logging messages.
     */
    var logger: Logger

    /**
     A boolean flag to disable event tracking when set to `true`. Defaults to `false`.
     */
    var optOut: Bool

    /**
     A boolean flag to enable GZip compression for network requests. Defaults to `true`.
     */
    var gzipEnabled: Bool

    /**
     The storage mechanism used to persist data. Defaults to in-built storage system, if no custom storage is provided.
     */
    var storage: Storage

    /**
     An array of flush policies defining how and when events are flushed to the data plane.
     */
    var flushPolicies: [FlushPolicy]

    /**
     A boolean flag indicating whether the SDK should automatically collect the device ID. Defaults to `true`.
     */
    var collectDeviceId: Bool
    
    /**
     A boolean flag indicating whether the SDK should track application lifecycle events. Defaults to `true`.
     */
    var trackApplicationLifecycleEvents: Bool
    
    /**
     A configuration instance for managing session settings.
     */
    var sessionConfiguration: SessionConfiguration

    // MARK: - Initialization

    /**
     Initializes a `Configuration` object with the specified parameters.
     
     - Parameters:
       - writeKey: The write key for authentication with the analytics service.
       - dataPlaneUrl: The URL for the data plane.
       - controlPlaneUrl: The URL for the control plane.
       - logger: The logger instance for logging messages.
       - optOut: A flag to disable event tracking when `true`. Defaults to `false`.
       - gzipEnaabled: A flag to enable GZip compression.
       - storage: The storage mechanism for persisting data.
       - flushPolicies: The flush policies for event flushing.
       - collectDeviceId: A flag to enable automatic collection of the device ID. Defaults to `true`.
       - trackApplicationLifecycleEvents: A flag to enable automatic tracking of the application lifecycle events. Defaults to `true`.
       - sessionConfiguration: A configuration instance for managing session settings.
 
     - Returns: An instance of `Configuration` with the specified settings.
     */
    public init(
        writeKey: String,
        dataPlaneUrl: String,
        controlPlaneUrl: String = Constants.DefaultConfig.controlPlaneUrl,
        logger: Logger = SwiftLogger(logLevel: Constants.Log.defaultLevel),
        optOut: Bool = false,
        gzipEnaabled: Bool = Constants.DefaultConfig.gzipEnabled,
        storage: Storage? = nil,
        flushPolicies: [FlushPolicy] = Constants.DefaultConfig.flushPolicies,
        collectDeviceId: Bool = Constants.DefaultConfig.willCollectDeviceId,
        trackApplicationLifecycleEvents: Bool = Constants.DefaultConfig.willTrackLifecycleEvents,
        sessionConfiguration: SessionConfiguration = SessionConfiguration()
    ) {
        self.writeKey = writeKey
        self.dataPlaneUrl = dataPlaneUrl
        self.controlPlaneUrl = controlPlaneUrl
        self.logger = logger
        self.optOut = optOut
        self.gzipEnabled = gzipEnaabled
        self.storage = storage ?? BasicStorage(writeKey: writeKey)
        self.flushPolicies = flushPolicies
        self.collectDeviceId = collectDeviceId
        self.trackApplicationLifecycleEvents = trackApplicationLifecycleEvents
        self.sessionConfiguration = sessionConfiguration
    }
}

// MARK: - SessionConfiguration
/**
 A configuration class for managing session settings.
 */
@objcMembers
public class SessionConfiguration {
    /**
     A flag indicating whether automatic session tracking is enabled.
     */
    var automaticSessionTracking: Bool
    
    /**
     The timeout duration for a session, in milliseconds.
     */
    var sessionTimeoutInMillis: UInt64
    
    /**
     Initializes a new session configuration instance.
     
     - Parameters:
        - automaticSessionTracking: A boolean indicating whether session tracking should be automatic. Default is `true`.
        - sessionTimeoutInMillis: The session timeout duration in milliseconds. Default is `300_000` (5 minutes).
     */
    public init(automaticSessionTracking: Bool = Constants.DefaultConfig.automaticSessionTrackingStatus, sessionTimeoutInMillis: UInt64 = Constants.DefaultConfig.sessionTimeoutInMillis) {
        self.automaticSessionTracking = automaticSessionTracking
        self.sessionTimeoutInMillis = sessionTimeoutInMillis
    }
}
