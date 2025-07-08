//
//  ObjCSessionConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

// MARK: - ObjCSessionConfigurationBuilder
/**
 A builder class for constructing `SessionConfiguration` instances for Objective-C usage.
 */
@objc(RSSSessionConfigurationBuilder)
public final class ObjCSessionConfigurationBuilder: NSObject {

    private var automaticSessionTracking: Bool = Constants.defaultConfig.automaticSessionTrackingStatus
    private var sessionTimeoutInMillis: UInt64 = Constants.defaultConfig.sessionTimeoutInMillis

    /**
     Initializes a new builder.
     */
    @objc
    public override init() {
        super.init()
    }

    /**
     Builds and returns the configured `SessionConfiguration` instance.
     */
    @objc
    public func build() -> SessionConfiguration {
        return SessionConfiguration(automaticSessionTracking: automaticSessionTracking, sessionTimeoutInMillis: sessionTimeoutInMillis)
    }

    /**
     Sets whether automatic session tracking is enabled.

     - Parameter track: A Boolean indicating whether automatic tracking should be enabled.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setAutomaticSessionTracking(_ track: Bool) -> Self {
        self.automaticSessionTracking = track
        return self
    }

    /**
     Sets the session timeout duration in milliseconds.

     - Parameter timeoutInMillis: A positive number representing the timeout duration.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setSessionTimeoutInMillis(_ timeoutInMillis: NSNumber) -> Self {
        if timeoutInMillis.int64Value >= 0 {
            self.sessionTimeoutInMillis = timeoutInMillis.uint64Value
        }
        return self
    }
}
