//
//  MigrationUtilsV1.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 20/12/25.
//

import Foundation

/**
 Utility methods for persistence operations including JSON encoding/decoding,
 file operations, and timestamp conversions.
 */
enum MigrationUtilsV1 {
    
    // MARK: - UserDefaults

    /**
     Creates a UserDefaults instance for the new Swift SDK
     - Parameter writeKey: The write key for the analytics instance
     - Returns: UserDefaults instance with the appropriate suite name, or nil if bundle identifier unavailable
     */
    static func rudderSwiftDefaults(_ writeKey: String) -> UserDefaults? {
        guard let suiteName = swiftSuiteName(for: writeKey) else { return nil }
        return UserDefaults(suiteName: suiteName)
    }

    /**
     Checks if the Swift SDK UserDefaults suite exists
     - Parameter writeKey: The write key for the analytics instance
     - Returns: True if the UserDefaults suite exists, false otherwise
     */
    static func isSwiftDefaultsAvailable(_ writeKey: String) -> Bool {
        guard let suiteName = swiftSuiteName(for: writeKey) else { return false }
        return UserDefaults.standard.persistentDomain(forName: suiteName) != nil
    }

    /// Generates the UserDefaults suite name for the Swift SDK
    private static func swiftSuiteName(for writeKey: String) -> String? {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        return "\(bundleIdentifier).analytics.\(writeKey)"
    }
    
    // MARK: - JSON Encoding/Decoding
    
    /**
     Encodes a dictionary as a JSON string
     - Parameter dictionary: Dictionary to encode
     - Returns: JSON string representation, or nil if encoding fails
     */
    static func encodeJSONDict(_ dictionary: [String: Any]?) -> String? {
        guard let dictionary = dictionary,
              JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
    
    /**
     Decodes a JSON dictionary from a string
     - Parameter jsonString: JSON string to decode
     - Returns: Decoded dictionary, or nil if decoding fails
     */
    static func decodeJSONDict(from jsonString: String?) -> [String: Any]? {
        guard let jsonString = jsonString,
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
    
    // MARK: - File Operations
    
    /**
     Reads the legacy plist file if it exists
     - Returns: Dictionary contents of the plist, or nil if file doesn't exist or can't be read
     */
    static func readPlist() -> [String: Any]? {
        let fileURL = persistenceFileURL()
        
        // Check if file exists before attempting to read
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        return NSDictionary(contentsOf: fileURL) as? [String: Any]
    }
    
    /**
     Reads UserDefaults values and returns them as a dictionary
     - Returns: Dictionary of legacy values from UserDefaults, or nil if none found
     */
    static func readLegacyUserDefaults() -> [String: Any]? {
        let userDefaults = UserDefaults.standard
        var dict: [String: Any] = [:]
        
        // Read all potential legacy keys
        if let anonymousId = userDefaults.string(forKey: PersistenceKeysV1.legacyAnonymousIdKey) {
            dict[PersistenceKeysV1.legacyAnonymousIdKey] = anonymousId
        }
        
        if let traits = userDefaults.string(forKey: PersistenceKeysV1.legacyTraitsKey) {
            dict[PersistenceKeysV1.legacyTraitsKey] = traits
        }
        
        if let sessionId = userDefaults.object(forKey: PersistenceKeysV1.legacySessionId) {
            dict[PersistenceKeysV1.legacySessionId] = sessionId
        }
        
        if let isAutoTrack = userDefaults.object(forKey: PersistenceKeysV1.legacyIsSessionAutoTrackEnabled) {
            dict[PersistenceKeysV1.legacyIsSessionAutoTrackEnabled] = isAutoTrack
        }
        
        if let lastEventTime = userDefaults.object(forKey: PersistenceKeysV1.legacyLastEventTimeStamp) {
            dict[PersistenceKeysV1.legacyLastEventTimeStamp] = lastEventTime
        }
        
        return dict.isEmpty ? nil : dict
    }
    
    /**
     Generates the URL for the legacy persistence plist file
     - Returns: URL pointing to the rsDefaultsPersistence.plist file
     */
    static func persistenceFileURL() -> URL {
        let directory: URL
        
#if os(tvOS)
        directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
#else
        directory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
#endif
        
        return directory.appendingPathComponent("rsDefaultsPersistence.plist")
    }
    
    /**
     Clears all legacy persistence data from both plist file and UserDefaults.standard
     
     This should be called after successful migration to clean up legacy data.
     */
    static func clearLegacyData() {
        // Delete legacy plist file
        let fileURL = persistenceFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("MigrationUtilsV1: Deleted legacy plist file")
            } catch {
                print("MigrationUtilsV1: Failed to delete legacy plist file: \(error)")
            }
        }
        
        // Remove legacy keys from UserDefaults.standard
        [PersistenceKeysV1.legacyAnonymousIdKey,
         PersistenceKeysV1.legacyTraitsKey,
         PersistenceKeysV1.legacySessionId,
         PersistenceKeysV1.legacyIsSessionAutoTrackEnabled,
         PersistenceKeysV1.legacyLastEventTimeStamp,
         PersistenceKeysV1.legacyApplicationVersion,
         PersistenceKeysV1.legacyApplicationBuild
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        UserDefaults.standard.synchronize()
        
        print("MigrationUtilsV1: Cleared legacy UserDefaults values")
    }
    
    // MARK: - Timestamp Conversion
    
    /**
     Converts a legacy wall-clock timestamp (timeIntervalSince1970) into a
     system uptime value (ProcessInfo.processInfo.systemUptime) expressed
     in milliseconds.
     
     This method is used during SDK migration where the legacy SDK stored
     the last activity time as an absolute timestamp, while the new SDK
     stores it as system uptime (time since last device boot).
     
     Conversion logic:
     - Read the current timestamp (t_now)
     - Read the current system uptime (u_now)
     - Calculate the system boot timestamp:
     bootTimestamp = t_now - u_now
     - Calculate the uptime at which the legacy event occurred:
     uptimeAtTimestamp = legacyTimestamp - bootTimestamp
     
     If the legacy timestamp occurred before the current system boot,
     the conversion is not possible and the method returns nil.
     
     Example:
     currentTimestamp = 1_725_000_000   (seconds since 1970)
     currentUptime    = 10_000          (seconds since last boot)
     
     bootTimestamp    = 1_724_990_000
     
     legacyTimestamp  = 1_724_995_000
     
     uptimeAtTimestamp = 5_000 seconds
     result            = 5_000_000 milliseconds
     
     Important notes:
     - This conversion only succeeds if the device has not rebooted since
     the legacy timestamp was recorded.
     - If a reboot occurred, returning nil is the correct and safe behavior.
     
     - Parameter timestamp:
     Legacy timestamp represented as timeIntervalSince1970.
     
     - Returns:
     System uptime in milliseconds corresponding to the legacy timestamp,
     or nil if the conversion is not valid.
     */
    static func convertTimestampToSystemUptime(_ timestamp: Double) -> UInt64? {
        let currentTimestamp = Date().timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime
        
        // Timestamp must be valid and in the past
        guard timestamp > 0, timestamp <= currentTimestamp else {
            print("MigrationUtilsV1: Invalid timestamp: \(timestamp)")
            return nil
        }
        
        // Calculate system boot time as a timestamp
        let bootTimestamp = currentTimestamp - currentUptime
        
        // Calculate uptime at the time of the legacy timestamp
        let uptimeAtTimestamp = timestamp - bootTimestamp
        guard uptimeAtTimestamp >= 0 else {
            print("MigrationUtilsV1: Timestamp predates system boot: \(timestamp)")
            return nil
        }
        
        // Convert seconds to milliseconds
        return UInt64(uptimeAtTimestamp * 1000)
    }
}

// MARK: - Persistence Keys
enum PersistenceKeysV1 {
    // Keys read from legacy storage (both plist and UserDefaults.standard)
    static let legacyAnonymousIdKey = "rl_anonymous_id"
    static let legacyUserIdKey = "userId"
    static let legacyTraitsKey = "rl_traits"
    
    static let legacySessionId = "rl_session_id"
    static let legacyLastEventTimeStamp = "rl_last_event_time_stamp"
    static let legacyIsSessionAutoTrackEnabled = "rl_session_auto_track_status"
    
    static let legacyApplicationVersion = "rl_application_version_key"
    static let legacyApplicationBuild = "rl_application_build_key"
    
    // Keys that may exist within traits dictionary
    static let traitsUserIdKey = "userId"
    static let traitsAnonymousIdKey = "anonymousId"
    
    // Keys used for storing values in the new Swift SDK
    static let anonymousIdKey = "anonymous_id"
    static let userIdKey = "user_id"
    static let traitsKey = "traits"
    
    static let sessionId = "session_id"
    static let isManualSession = "is_manual_session"
    static let isSessionStart = "is_session_start"
    static let lastActivityTime = "last_activity_time"
    
    static let applicationVersion = "rudder.app_version"
    static let applicationBuild = "rudder.app_build"
}
