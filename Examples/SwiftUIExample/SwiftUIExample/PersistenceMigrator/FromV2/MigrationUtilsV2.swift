//
//  MigrationUtilsV2.swift
//  MultiRSA
//
//  Created by Satheesh Kannan on 24/12/25.
//

import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import Cocoa
#endif

/**
 Utility methods for V2 persistence operations including JSON encoding/decoding
 and timestamp conversions. V2 uses only UserDefaults.standard as legacy storage.
 */
enum MigrationUtilsV2 {
    
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
    
    // MARK: - Legacy UserDefaults Operations
    
    /**
     Reads UserDefaults.standard values and returns them as a dictionary
     - Returns: Dictionary of legacy V2 values from UserDefaults, or nil if none found
     */
    static func readLegacyUserDefaults() -> [String: Any]? {
        let userDefaults = UserDefaults.standard
        var dict: [String: Any] = [:]
        
        // Allowed classes for unarchiving traits
        let allowedJSONClasses: [AnyClass] = [
            NSDictionary.self,
            NSArray.self,
            NSString.self,
            NSNumber.self,
            NSNull.self
        ]
        
        // Read all potential legacy V2 keys
        if let userId = userDefaults.string(forKey: PersistenceKeysV2.legacyUserIdKey) {
            dict[PersistenceKeysV2.legacyUserIdKey] = userId
        }
        
        if let traitsData = userDefaults.data(forKey: PersistenceKeysV2.legacyTraitsKey), let traits = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedJSONClasses, from: traitsData) as? [String: Any] {
            dict[PersistenceKeysV2.legacyTraitsKey] = traits
        }
        
        if let sessionId = userDefaults.object(forKey: PersistenceKeysV2.legacySessionId) {
            dict[PersistenceKeysV2.legacySessionId] = sessionId
        }
        
        if let isManualTrack = userDefaults.object(forKey: PersistenceKeysV2.legacySessionManualTrackStatus) {
            dict[PersistenceKeysV2.legacySessionManualTrackStatus] = isManualTrack
        }
        
        if let lastEventTime = userDefaults.object(forKey: PersistenceKeysV2.legacyLastEventTimeStamp) {
            dict[PersistenceKeysV2.legacyLastEventTimeStamp] = lastEventTime
        }
        
        if let appVersion = userDefaults.object(forKey: PersistenceKeysV2.legacyApplicationVersion) {
            dict[PersistenceKeysV2.legacyApplicationVersion] = appVersion
        }
        
        if let appBuild = userDefaults.object(forKey: PersistenceKeysV2.legacyApplicationBuild) {
            dict[PersistenceKeysV2.legacyApplicationBuild] = appBuild
        }
        
        // Anonymous ID not stored explicitly, it is derived from device `identifierForVendor`
        // If other data exists, add anonymousId to the dictionary
        if !dict.isEmpty, let anonymousId = MigrationUtilsV2.getAnonymousId() {
            dict[PersistenceKeysV2.anonymousIdKey] = anonymousId
        }
        
        return dict.isEmpty ? nil : dict
    }
    
    /**
     Clears all legacy V2 persistence data from UserDefaults.standard
     
     This should be called after successful migration to clean up legacy data.
     */
    static func clearLegacyData() {
        // Remove legacy keys from UserDefaults.standard
        [PersistenceKeysV2.legacyUserIdKey,
         PersistenceKeysV2.legacyTraitsKey,
         PersistenceKeysV2.legacySessionId,
         PersistenceKeysV2.legacySessionManualTrackStatus,
         PersistenceKeysV2.legacyLastEventTimeStamp,
         PersistenceKeysV2.legacyApplicationVersion,
         PersistenceKeysV2.legacyApplicationBuild
        ].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        UserDefaults.standard.synchronize()
        
        print("MigrationUtilsV2: Cleared legacy UserDefaults values")
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
            print("MigrationUtilsV2: Invalid timestamp: \(timestamp)")
            return nil
        }
        
        // Calculate system boot time as a timestamp
        let bootTimestamp = currentTimestamp - currentUptime
        
        // Calculate uptime at the time of the legacy timestamp
        let uptimeAtTimestamp = timestamp - bootTimestamp
        guard uptimeAtTimestamp >= 0 else {
            print("MigrationUtilsV2: Timestamp predates system boot: \(timestamp)")
            return nil
        }
        
        // Convert seconds to milliseconds
        return UInt64(uptimeAtTimestamp * 1000)
    }
    
    // MARK: - Anonymous ID Retrieval
    /**
     Retrieves the device's anonymous ID used in legacy V2 storage.
     - Returns: The anonymous ID string, or nil if unavailable
     */
    private static func getAnonymousId() -> String? {
#if os(iOS) || os(tvOS)
        return UIDevice.current.identifierForVendor?.uuidString.lowercased()
#elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor?.uuidString.lowercased()
#elseif os(macOS)
        return macAddress(bsd: "en0")
#endif
    }
    
    /**
     Retrieves the MAC address for a given BSD interface name on macOS.
     - Parameter bsd: The BSD interface name (e.g., "en0")
     - Returns: The MAC address string, or nil if unavailable
     */
    private static func macAddress(bsd: String) -> String? {
        let macAddressLength = 6
        let separator = ":"
        let mibSize = 6
        let indexOffset = 1
        
        var length: size_t = 0
        var buffer: [CChar]
        
        let bsdIndex = Int32(if_nametoindex(bsd))
        guard bsdIndex != 0 else { return nil }
        
        let bsdData = Data(bsd.utf8)
        var managementInfoBase: [Int32] = [CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, bsdIndex]
        
        guard sysctl(&managementInfoBase, u_int(mibSize), nil, &length, nil, 0) >= 0 else {
            return nil
        }
        
        buffer = [CChar](repeating: 0, count: length)
        guard sysctl(&managementInfoBase, u_int(mibSize), &buffer, &length, nil, 0) >= 0 else {
            return nil
        }
        
        let infoData = Data(bytes: buffer, count: length)
        let startIndex = MemoryLayout<if_msghdr>.stride + indexOffset
        
        guard let rangeOfToken = infoData[startIndex...].range(of: bsdData) else {
            return nil
        }
        
        let lower = rangeOfToken.upperBound
        let upper = lower + macAddressLength
        guard upper <= infoData.count else { return nil }
        
        let macAddressData = infoData[lower..<upper]
        let addressBytes = macAddressData.map { String(format: "%02x", $0) }
        return addressBytes.joined(separator: separator)
    }
}

// MARK: - Persistence Keys
enum PersistenceKeysV2 {
    // Keys read from legacy storage (UserDefaults.standard)
    static let legacyUserIdKey = "rs_user_id"
    static let legacyTraitsKey = "rs_traits"
    
    static let legacySessionId = "rl_session_id"
    static let legacyLastEventTimeStamp = "rl_last_event_time_stamp"
    static let legacySessionManualTrackStatus = "rl_session_manual_track_status"
    
    static let legacyApplicationVersion = "rs_application_version_key"
    static let legacyApplicationBuild = "rs_application_build_key"
    
    // Keys that may exist within traits dictionary
    static let traitsIdKey = "id"
    static let traitsUserIdKey = "userId"
    static let traitsAnonymousIdKey = "anonymousId"
    
    // Keys used for storing values in the new Swift SDK
    static let anonymousIdKey = "anonymous_id"
    static let userIdKey = "user_id"
    static let traitsKey = "traits"
    
    static let sessionId = "session_id"
    static let isManualSession = "is_manual_session"
    static let lastActivityTime = "last_activity_time"
    
    static let applicationVersion = "rudder.app_version"
    static let applicationBuild = "rudder.app_build"
}
