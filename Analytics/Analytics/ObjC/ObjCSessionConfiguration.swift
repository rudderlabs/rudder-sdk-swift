//
//  ObjCSessionConfiguration.swift
//  Analytics
//
//  Created by Satheesh Kannan on 23/05/25.
//

import Foundation

// MARK: - ObjCSessionConfiguration
/**
 A wrapper class that exposes the Swift `SessionConfiguration` to Objective-C.
 */
@objc(RSSessionConfiguration)
public final class ObjCSessionConfiguration: NSObject {

    let configuration: SessionConfiguration

    /** Enables or disables automatic session tracking. */
    @objc internal(set) public var automaticSessionTracking: Bool {
        get { configuration.automaticSessionTracking }
        set { configuration.automaticSessionTracking = newValue }
    }

    /** The session timeout duration in milliseconds. */
    @objc internal(set) public var sessionTimeoutInMillis: UInt64 {
        get { configuration.sessionTimeoutInMillis }
        set { configuration.sessionTimeoutInMillis = newValue }
    }

    /**
     Initializes a new session configuration with default values.
     */
    override init() {
        self.configuration = SessionConfiguration()
        super.init()
    }

    /**
     Initializes the session configuration using an existing `SessionConfiguration` instance.

     - Parameter configuration: The existing session configuration to wrap.
     */
    public init(configuration: SessionConfiguration) {
        self.configuration = configuration
        super.init()
    }
}

// MARK: - ObjCSessionConfigurationBuilder
/**
 A builder class for constructing `ObjCSessionConfiguration` instances for Objective-C usage.
 */
@objc(RSSessionConfigurationBuilder)
public final class ObjCSessionConfigurationBuilder: NSObject {

    let configuration: ObjCSessionConfiguration

    /**
     Initializes a new builder with a default session configuration.
     */
    @objc
    public override init() {
        configuration = ObjCSessionConfiguration()
        super.init()
    }

    /**
     Builds and returns the configured `ObjCSessionConfiguration` instance.
     */
    @objc
    public func build() -> ObjCSessionConfiguration {
        return configuration
    }

    /**
     Sets whether automatic session tracking is enabled.

     - Parameter track: A Boolean indicating whether automatic tracking should be enabled.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setAutomaticSessionTracking(_ track: Bool) -> Self {
        self.configuration.automaticSessionTracking = track
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
        if timeoutInMillis.int64Value > 0 {
            self.configuration.sessionTimeoutInMillis = timeoutInMillis.uint64Value
        }
        return self
    }
}
