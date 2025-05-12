//
//  Constants.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/02/25.
//

import Foundation

// MARK: - Constants
/// A container for all constants used throughout the SDK.
@objcMembers
public class Constants: NSObject {
    /// Private initializer to prevent instantiation.
    private override init() { super.init() }

    /// Logging-related constants.
    public static let log = _Log()

    /// Constants for controlling event count-based flush behavior.
    public static let flushEventCount = _FlushEventCount()

    /// Constants for controlling time interval-based flush behavior.
    public static let flushInterval = _FlushInterval()

    /// Default configuration values for the SDK.
    public static let defaultConfig = _DefaultConfig()

    /// Storage key identifiers used internally (not exposed publicly).
    static let storageKeys = _StorageKeys()

    /// Payload-specific constants used in network requests.
    static let payload = _Payload()
}

// swiftlint:disable type_name
/// Constants related to logging configurations.
@objcMembers
public class _Log: NSObject {
    /// The default log tag used for identifying SDK logs.
    public let tag: String = "Rudder-Analytics"

    /// The default log level for the SDK.
    public let defaultLevel: LogLevel = .none

    /// Message printed after the analytics instance shuts down.
    public let shutdownMessage: String = "Analytics instance has been shut down. No further operations are allowed."
}

/// Constants related to keys used for persistent storage within the SDK.
class _StorageKeys: NSObject {
    /// Key for storing the anonymous user identifier.
    let anonymousId = "anonymous_id"

    /// Key for storing the identified user ID.
    let userId = "user_id"

    /// Key for storing user traits.
    let traits = "traits"

    /// Key for storing source configuration data.
    let sourceConfig = "source_config"

    /// Key for storing the session identifier.
    let sessionId = "session_id"

    /// Key for identifying if the session was manually triggered.
    let isManualSession = "is_manual_session"

    /// Key for determining if the session just started.
    let isSessionStart = "is_session_start"

    /// Key for storing the timestamp of the last user activity.
    let lastActivityTime = "last_activity_time"

    /// Key for storing the app version.
    let appVersion = "rudder.app_version"

    /// Key for storing the app build number.
    let appBuild = "rudder.app_build"
}

/// Constants for event count-based flush triggers.
@objcMembers
public class _FlushEventCount: NSObject {
    /// Default number of events before triggering a flush.
    public let `default` = 30

    /// Minimum number of events allowed before triggering a flush.
    public let min: Int = 1

    /// Maximum number of events allowed before triggering a flush.
    public let max: Int = 100
}

/// Constants for time interval-based flush triggers.
@objcMembers
public class _FlushInterval: NSObject {
    /// Default time interval for triggering a flush, in milliseconds (10 seconds).
    public let `default`: UInt64 = 10_000

    /// Minimum time interval allowed for triggering a flush, in milliseconds.
    public let min: UInt64 = 1
}

/// Constants used when creating payloads for network requests.
class _Payload: NSObject {
    /// Placeholder used for adding sent-at timestamps in event payloads.
    let sentAtPlaceholder = "{{_RSA_DEF_SENT_AT_TS_}}"

    /// Identifier for the SDK channel type.
    let channel = "mobile"

    /// Default integration settings applied to events.
    let integration = ["All": true]
}

/// Default configuration values used throughout the SDK.
@objcMembers
public class _DefaultConfig: NSObject {
    /// Default storage mode used for persisting data.
    public let storageMode: StorageMode = .disk

    /// Default control plane URL for the SDK.
    public let controlPlaneUrl: String = "https://api.rudderlabs.com"

    /// Whether GZIP compression is enabled by default.
    public let gzipEnabled: Bool = true

    /// Default policies used to determine when to flush events.
    public let flushPolicies: [FlushPolicy] = [
        StartupFlushPolicy(),
        FrequencyFlushPolicy(),
        CountFlushPolicy()
    ]

    /// Whether to collect device identifiers by default.
    public let willCollectDeviceId: Bool = true

    /// Whether to track application lifecycle events by default.
    public let willTrackLifecycleEvents: Bool = true

    /// Whether session tracking is automatic by default.
    public let automaticSessionTrackingStatus: Bool = true

    /// Default session timeout duration in milliseconds (5 minutes).
    public let sessionTimeoutInMillis: UInt64 = 300_000

    /// Default query parameters added to outgoing requests.
    let queryParams = ["p": "ios", "v": "\(RSVersion)"]

    /// Special signal string used to trigger uploads.
    let uploadSignal = "#!upload!#"
}
// swiftlint:enable type_name

// MARK: - RSVersion
/**
 The version number of the Swift SDK.
 
 **Important:**
 Do not edit this value unless performing a manual release.
 */
let RSVersion: String = "1.31.0"
