//
//  PersistenceMigrator.swift
//  MultiRSA
//
//  Created by Satheesh Kannan on 20/12/25.
//

import Foundation

/**
 A utility class for reading legacy Rudder SDK (iOS-V1) persistence data and migrating it to the new Swift SDK.
 
 Reads legacy data from plist files or UserDefaults, then stores it in the new Swift SDK's UserDefaults suite.
 Handles anonymous ID, user ID, traits, and session data migration.
 
 - Important: Call `restorePersistence()` only once during app initialization, before initializing the RudderStack SDK.
 This method is not thread-safe for concurrent calls. Ensure it is called from a single location (e.g., in
 `application(_:didFinishLaunchingWithOptions:)` or app initialization).
 
 Usage:
 ```swift
 let migrator = PersistenceMigrator(writeKey: "writeKey")
 migrator.restorePersistence()
 ```
 */
final class PersistenceMigrator {
    
    // MARK: - Properties
    
    /** The write key used to identify the analytics instance */
    let writeKey: String
    
    // MARK: - Initialization
    
    /**
     Initializes the persistence migrator with the specified write key
     
     - Parameter writeKey: The write key for the analytics instance
     */
    init(writeKey: String) {
        self.writeKey = writeKey
    }
    
    // MARK: - Public API
    
    /**
     Reads legacy persistence data and migrates it to Swift SDK UserDefaults.
     
     Checks plist file first, then UserDefaults fallback. Logs migration progress. Clears legacy values after successful migration.
     Returns without performing migration, if no legacy data found.
     */
    func restorePersistence() {
        let persistedValues = readPersistence()
        
        guard let persistedValues = persistedValues, !persistedValues.isEmpty else {
            print("PersistenceMigrator: No persisted values found for migration")
            return
        }
        
        guard let userDefaults = MigrationUtils.rudderSwiftDefaults(writeKey) else {
            print("PersistenceMigrator: Failed to access Swift SDK UserDefaults for writeKey: \(writeKey)")
            return
        }
        
        print("PersistenceMigrator: Found persisted values, beginning migration for writeKey: \(writeKey)")
        
        // Migrate anonymous ID
        if let anonymousId = persistedValues[PersistenceKeys.anonymousIdKey] as? String {
            userDefaults.set(anonymousId, forKey: PersistenceKeys.anonymousIdKey)
            print("PersistenceMigrator: Migrated anonymous ID")
        }
        
        // Migrate user ID
        if let userId = persistedValues[PersistenceKeys.userIdKey] as? String {
            userDefaults.set(userId, forKey: PersistenceKeys.userIdKey)
            print("PersistenceMigrator: Migrated user ID")
        }
        
        // Migrate traits
        if var traits = persistedValues[PersistenceKeys.traitsKey] as? [String: Any] {
            // Remove user ID and anonymous ID from traits as they are stored separately
            traits.removeValue(forKey: PersistenceKeys.traitsAnonymousIdKey)
            traits.removeValue(forKey: PersistenceKeys.traitsUserIdKey)
            
            if let encodedTraits = MigrationUtils.encodeJSONDict(traits) {
                userDefaults.set(encodedTraits, forKey: PersistenceKeys.traitsKey)
                print("PersistenceMigrator: Migrated user traits")
            } else {
                print("PersistenceMigrator: Failed to encode traits for migration, traits data will not migrated")
            }
        }
        
        // Migrate session-related values
        migrateSessionValues(from: persistedValues, to: userDefaults)
        
        // Force synchronization to ensure migrated data is persisted to disk before clearing legacy data
        userDefaults.synchronize()
        print("PersistenceMigrator: Successfully completed persistence migration for writeKey: \(writeKey)")
        
        // Clear legacy data after successful migration
        MigrationUtils.clearLegacyData()
    }
    
    /**
     Reads legacy persistence data from plist (preferred) or UserDefaults (fallback).
     
     - Returns: Dictionary containing the persisted values, or nil if none found
     */
    func readPersistence() -> [String: Any]? {
        // Try plist first, then UserDefaults fallback
        if let plistValues = readFromPlist() {
            print("PersistenceMigrator: Found persisted values in plist file for writeKey: \(writeKey)")
            return plistValues
        }
        
        if let userDefaultsValues = readFromUserDefaults() {
            print("PersistenceMigrator: Found persisted values in UserDefaults for writeKey: \(writeKey)")
            return userDefaultsValues
        }
        
        print("PersistenceMigrator: No persisted values found in plist or UserDefaults for writeKey: \(writeKey)")
        return nil
    }
}

// MARK: - Reading Legacy Data
private extension PersistenceMigrator {
    
    /**
     Attempts to read persisted values from the legacy plist file
     - Returns: Dictionary of persisted values, or nil if plist doesn't exist or can't be read
     */
    func readFromPlist() -> [String: Any]? {
        guard let dict = MigrationUtils.readPlist() else {
            return nil
        }
        return extractValuesFromDictionary(dict)
    }
    
    /**
     Attempts to read persisted values from UserDefaults.standard
     - Returns: Dictionary of persisted values, or nil if none found
     */
    func readFromUserDefaults() -> [String: Any]? {
        guard let dict = MigrationUtils.readLegacyUserDefaults() else {
            return nil
        }
        return extractValuesFromDictionary(dict)
    }
    
    /**
     Extracts and transforms values from a source dictionary
     - Parameter dict: Source dictionary containing legacy values
     - Returns: Dictionary of transformed values, or nil if no values found
     */
    func extractValuesFromDictionary(_ dict: [String: Any]) -> [String: Any]? {
        var result: [String: Any] = [:]
        
        // Extract anonymous ID
        if let anonymousId = dict[PersistenceKeys.legacyAnonymousIdKey] as? String {
            result[PersistenceKeys.anonymousIdKey] = anonymousId
        }
        
        // Extract traits (stored as JSON string)
        if let traits = MigrationUtils.decodeJSONDict(from: dict[PersistenceKeys.legacyTraitsKey] as? String) {
            result[PersistenceKeys.traitsKey] = traits
            
            // Extract user ID from within traits
            if let userId = traits[PersistenceKeys.legacyUserIdKey] as? String {
                result[PersistenceKeys.userIdKey] = userId
            }
        }
        
        // Extract session-related values
        extractSessionValues(from: dict, into: &result)
        
        return result.isEmpty ? nil : result
    }
    
    /**
     Extracts session-related values from dictionary
     - Parameters:
     - dict: Source dictionary containing legacy session values
     - result: Inout dictionary to store extracted values
     */
    func extractSessionValues(from dict: [String: Any], into result: inout [String: Any]) {
        // Extract session ID (required for all session migration)
        guard let sessionIdNumber = dict[PersistenceKeys.legacySessionId] as? NSNumber else {
            print("PersistenceMigrator: No legacy session ID found in dictionary, skipping session migration")
            return
        }
        
        // Extract and convert lastEventTimeStamp to lastActivityTime
        if let lastEventTimeNumber = dict[PersistenceKeys.legacyLastEventTimeStamp] as? NSNumber {
            let lastEventTime = lastEventTimeNumber.doubleValue
            
            guard let convertedTime = MigrationUtils.convertTimestampToSystemUptime(lastEventTime) else {
                print("PersistenceMigrator: Failed to convert lastEventTimeStamp from dictionary, skipping session migration")
                return
            }
            result[PersistenceKeys.lastActivityTime] = convertedTime
        }
        
        result[PersistenceKeys.sessionId] = sessionIdNumber.uint64Value
        
        // Extract and convert isSessionAutoTrackEnabled to isManualSession
        if let isAutoTrackNumber = dict[PersistenceKeys.legacyIsSessionAutoTrackEnabled] as? NSNumber {
            let isAutoTrack = isAutoTrackNumber.boolValue
            result[PersistenceKeys.isManualSession] = !isAutoTrack
        }
    }
}

// MARK: - Migration Helpers
private extension PersistenceMigrator {
    
    /**
     Migrates session-related values from persisted data to Swift SDK UserDefaults
     - Parameters:
     - persistedValues: Dictionary containing the persisted values
     - userDefaults: Target UserDefaults instance for Swift SDK
     */
    func migrateSessionValues(from persistedValues: [String: Any], to userDefaults: UserDefaults) {
        // Check if session ID exists first - this is required for all session migration
        guard let sessionId = persistedValues[PersistenceKeys.sessionId] as? UInt64 else {
            print("PersistenceMigrator: No session ID found, skipping session migration")
            return
        }
        
        print("PersistenceMigrator: Migrating session values")
        
        // Migrate session ID
        userDefaults.set(String(sessionId), forKey: PersistenceKeys.sessionId)
        print("PersistenceMigrator: Migrated session ID: \(sessionId)")
        
        // Migrate isManualSession (toggled value of legacyIsSessionAutoTrackEnabled)
        if let isManualSession = persistedValues[PersistenceKeys.isManualSession] as? Bool {
            userDefaults.set(isManualSession, forKey: PersistenceKeys.isManualSession)
            print("PersistenceMigrator: Migrated isManualSession: \(isManualSession)")
        }
        
        // Set isSessionStart to false, since the session is being restored
        userDefaults.set(false, forKey: PersistenceKeys.isSessionStart)
        print("PersistenceMigrator: Set isSessionStart to false")
        
        // Migrate lastActivityTime
        if let lastActivityTime = persistedValues[PersistenceKeys.lastActivityTime] as? UInt64 {
            userDefaults.set(String(lastActivityTime), forKey: PersistenceKeys.lastActivityTime)
            print("PersistenceMigrator: Migrated lastActivityTime: \(lastActivityTime)")
        }
    }
}
