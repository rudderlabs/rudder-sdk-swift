//
//  Configuration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 16/08/24.
//

import Foundation
/**
 This class is responsible for configuring the entire SDK.
 */
// MARK: - Configuration
@objcMembers
public class Configuration {
    var writeKey: String
    var dataPlaneUrl: String
    var controlPlaneUrl: String
    var logger: Logger
    var optOut: Bool
    var gzipEnabled: Bool
    var storage: Storage
    var flushPolicies: [FlushPolicy]
    var collectDeviceId: Bool
    
    public init(writeKey: String,
                dataPlaneUrl: String,
                controlPlaneUrl: String = Constants.defaultControlPlaneUrl,
                logger: Logger = SwiftLogger(logLevel: Constants.defaultLogLevel),
                optOut: Bool = false,
                gzipEnaabled: Bool = Constants.defaultGZipStatus,
                storage: Storage? = nil,
                flushPolicies: [FlushPolicy] = Constants.defaultFlushPolicies,
                collectDeviceId: Bool = true) {
        self.writeKey = writeKey
        self.dataPlaneUrl = dataPlaneUrl
        self.controlPlaneUrl = controlPlaneUrl
        self.logger = logger
        self.optOut = optOut
        self.gzipEnabled = gzipEnaabled
        self.storage = storage ?? BasicStorage(writeKey: writeKey)
        self.flushPolicies = flushPolicies
        self.collectDeviceId = collectDeviceId
    }
}
