//
//  Constants.swift
//  Analytics
//
//  Created by Satheesh Kannan on 11/02/25.
//

import Foundation

public struct Constants {
    private init() {} // Prevent instantiation
}

// MARK: - Log
extension Constants {
    public struct Log {
        public static let tag: String = "Rudder-Analytics"
        public static let defaultLevel: LogLevel = .none
        
        private init() {}
    }
}

// MARK: - Storage
extension Constants { // need changes
    public struct StorageKeys {
        public static let anonymousId = "anonymous_id"
        public static let userId = "user_id"
        public static let traits = "traits"
        public static let externalIds = "external_ids"
        public static let sourceConfig = "source_config"
        
        private init() {}
    }
}

// MARK: - Flush Policies
extension Constants {
    public struct Flush {
        public struct EventCount {
            public static let `default` = 30
            public static let min = 1
            public static let max = 100
            
            private init() {}
        }
        
        public struct Interval {
            public static let `default`: Double = 10_000 // 10 seconds
            public static let min: Double = 1
        }
        
        private init() {}
    }
    
}

// MARK: - Payload
extension Constants {
    public struct Payload {
        static let maxSize: Int64 = 32 * 1024 // 32 KB
        static let maxBatchSize: Int64 = 500 * 1024 // 500 KB
        static let sentAtPlaceholder = "{{_RSA_DEF_SENT_AT_TS_}}"
        static let channel = "mobile"
        static let integration = ["All": true]
        
        private init() {}
    }
}

// MARK: - Defaults
extension Constants {
    public struct DefaultConfig {
        public static let storageMode: StorageMode = .disk
        public static let controlPlaneUrl: String = "https://api.rudderlabs.com"
        public static let gzipEnabled: Bool = true
        public static let flushPolicies: [FlushPolicy] = [StartupFlushPolicy(), FrequencyFlushPolicy(), CountFlushPolicy()]
        public static let willCollectDeviceId: Bool = true
        static let queryParams = ["p": "ios", "v": "\(RSVersion)"]
        static let uploadSignal = "#!upload!#"
        
        private init() {}
    }
}
