//
//  Constants.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/02/25.
//

import Foundation

// MARK: - Constants
/// A struct for all constants used throughout the SDK.
public struct Constants {
    /// Private initializer to prevent instantiation.
    private init() {
        /* Prevent instantiation (no-op) */
    }
}

// MARK: - Log
extension Constants {
    /// Constants related to logging configurations.
    public struct Log {
        /// The default log tag used for identifying SDK logs.
        public static let tag: String = "Rudder-Analytics"
        
        /// The default log level for the SDK.
        public static let defaultLevel: LogLevel = .none
        
        /// Message printed after the analytics instance shuts down, indicating no further operations are allowed.
        static let shutdownMessage = "Analytics instance has been shut down. No further operations are allowed."
        
        /// Private initializer to prevent instantiation.
        private init() {
            /* Prevent instantiation (no-op) */
        }
    }
}

// MARK: - Storage
extension Constants {
    /// Constants related to storage keys used within the SDK.
    struct StorageKeys {
        /// Key for storing the anonymous user identifier.
        static let anonymousId = "anonymous_id"
        
        /// Key for storing the user identifier.
        static let userId = "user_id"
        
        /// Key for storing user traits.
        static let traits = "traits"
        
        /// Key for storing source configuration data.
        static let sourceConfig = "source_config"
        
        /// Key for storing session id.
        static let sessionId = "session_id"
        
        /// Key for storing session type.
        static let isManualSession = "is_manual_session"
        
        /// Key for storing session state.
        static let isSessionStart = "is_session_start"
        
        /// Key for storing session last activity time.
        static let lastActivityTime = "last_activity_time"
        
        /// Key for storing app version.
        static let appVersion = "rudder.app_version"
        
        /// Key for storing app build.
        static let appBuild = "rudder.app_build"
        
        /// Private initializer to prevent instantiation.
        private init() {
            /* Prevent instantiation (no-op) */
        }
    }
}

// MARK: - Flush Policies
extension Constants {
    /// Constants related to flush configurations.
    public struct Flush {
        /// Constants for event count-based flush triggers.
        public struct EventCount {
            /// Default number of events before triggering a flush.
            public static let `default` = 30
            
            /// Minimum number of events allowed before triggering a flush.
            public static let min = 1
            
            /// Maximum number of events allowed before triggering a flush.
            public static let max = 100
            
            /// Private initializer to prevent instantiation.
            private init() {
                /* Prevent instantiation (no-op) */
            }
        }
        
        /// Constants for time interval-based flush triggers.
        public struct Interval {
            /// Default time interval for triggering a flush (in milliseconds).
            public static let `default`: Double = 10_000 // 10 seconds
            
            /// Minimum time interval for triggering a flush (in milliseconds).
            public static let min: Double = 1
        }
        
        /// Private initializer to prevent instantiation.
        private init() {
            /* Prevent instantiation (no-op) */
        }
    }
}

// MARK: - Payload
extension Constants {
    /// Constants used when creating payloads for network requests.
    struct Payload {
        /// Placeholder used for adding sent-at timestamps.
        static let sentAtPlaceholder = "{{_RSA_DEF_SENT_AT_TS_}}"
        
        /// Channel identifier for the SDK.
        static let channel = "mobile"
        
        /// Default integration settings.
        static let integration = ["All": true]
        
        /// Private initializer to prevent instantiation.
        private init() {
            /* Prevent instantiation (no-op) */
        }
    }
}

// MARK: - Defaults
extension Constants {
    /// Default configuration values used in the SDK.
    public struct DefaultConfig {
        /// Default storage mode for persisting data.
        public static let storageMode: StorageMode = .disk
        
        /// Default control plane URL for the SDK.
        public static let controlPlaneUrl: String = "https://api.rudderlabs.com"
        
        /// Default setting for enabling GZIP compression.
        public static let gzipEnabled: Bool = true
        
        /// Default flush policies applied when sending events.
        public static let flushPolicies: [FlushPolicy] = [
            StartupFlushPolicy(),
            FrequencyFlushPolicy(),
            CountFlushPolicy()
        ]
        
        /// Default setting for collecting device identifiers.
        public static let willCollectDeviceId: Bool = true
        
        /// Default setting for tracking application lifecycle events.
        public static let willTrackLifecycleEvents: Bool = true
        
        /// Default setting for indicating whether session tracking should be automatic.
        public static let automaticSessionTrackingStatus: Bool = true
        
        /// Default setting for session timeout duration in milliseconds(5 minutes).
        public static let sessionTimeoutInMillis: UInt64 = 300_000
        
        /// Default query parameters added to requests.
        static let queryParams = ["p": "ios", "v": "\(RSVersion)"]
        
        /// Signal used to trigger uploads.
        static let uploadSignal = "#!upload!#"
        
        /// Private initializer to prevent instantiation.
        private init() {
            /* Prevent instantiation (no-op) */
        }
    }
}

// MARK: - RSVersion
/**
 The version number of the Swift SDK.
 
 **Important:**
 Do not edit this value unless performing a manual release.
 */
let RSVersion: String = "1.31.0"
