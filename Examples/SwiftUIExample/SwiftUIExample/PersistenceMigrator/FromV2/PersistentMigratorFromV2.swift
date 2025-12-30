//
//  PersistentMigratorFromV2.swift
//  MultiRSA
//
//  Created by Satheesh Kannan on 24/12/25.
//

import Foundation

// MARK: - PersistentMigratorFromV2

/**
 Migrates persistence data from the Rudder iOS SDK V2 to the new Swift SDK.

 This class reads data stored by the V2 SDK from UserDefaults.standard and writes it
 to the Swift SDK's UserDefaults suite. It handles migration of:
 - Anonymous Id
 - User ID
 - User traits
 - Session data
 - Application version and build

 Note:
 - V2 SDK stores data only in UserDefaults.standard.
 - V2 SDK don't stores the anonymousId anywhere it uses current device's `identifierForVendor` instead.

 ## Usage

 Call `restorePersistence()` once during app initialization, **before** initializing the RudderStack Swift SDK:

 ```swift
 // In AppDelegate or App init
 let migrator = PersistentMigratorFromV2(writeKey: "your_write_key")
 migrator.restorePersistence()

 // Then initialize the Swift SDK
 let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
 let analytics = Analytics(configuration: config)
 ```

 ## Inspecting Legacy Data

 Use `readPersistence()` to inspect what data will be migrated:

 ```swift
 let migrator = PersistentMigratorFromV2(writeKey: "your_write_key")
 if let legacyData = migrator.readPersistence() {
     print("Data to migrate: \(legacyData)")
 }
 ```
 */
public final class PersistentMigratorFromV2 {

    // MARK: - Properties

    /// The write key used to identify the Swift SDK's UserDefaults suite
    private let writeKey: String

    // MARK: - Initialization

    /**
     Creates a new persistence migrator.

     - Parameter writeKey: The write key for your RudderStack Swift SDK instance
     */
    public init(writeKey: String) {
        self.writeKey = writeKey
    }

    // MARK: - Public API

    /**
     Reads legacy V2 SDK persistence data without performing migration.

     Use this method to inspect what data will be migrated before calling `restorePersistence()`.

     - Returns: Dictionary containing legacy data, or `nil` if no legacy data exists.

     The dictionary contains the following keys (if available):
     - `anonymousId`: The anonymous ID (String)
     - `userId`: The user ID (String)
     - `traits`: User traits dictionary ([String: Any])
     - `sessionId`: Session ID (UInt64)
     - `lastActivityTime`: Last activity time in milliseconds (UInt64)
     - `isManualSession`: Whether session tracking is manual (Bool)
     - `applicationVersion`: The application version (String)
     - `applicationBuild`: The application build number (String)
     */
    public func readPersistence() -> [String: Any]? {
        guard let legacyData = extractLegacyData() else {
            return nil
        }
        return legacyData.toDictionary()
    }

    /**
     Restores legacy V2 SDK persistence data to the Swift SDK.

     This method:
     1. Checks if Swift SDK storage already exists (aborts if so)
     2. Reads legacy data from UserDefaults.standard
     3. Transforms and writes data to the Swift SDK's storage
     4. Clears legacy data after successful migration

     Safe to call multiple times - returns early if Swift SDK data or no legacy data exists.
     */
    public func restorePersistence() {
        guard !MigrationUtilsV2.isSwiftDefaultsAvailable(writeKey) else {
            log("Swift SDK storage already exists, skipping migration")
            return
        }

        guard let legacyData = extractLegacyData() else {
            log("No legacy data found, skipping migration")
            return
        }

        guard let targetDefaults = MigrationUtilsV2.rudderSwiftDefaults(writeKey) else {
            log("Failed to access Swift SDK storage for writeKey: \(writeKey)")
            return
        }

        log("Starting migration for writeKey: \(writeKey)")

        writeMigratedData(legacyData, to: targetDefaults)
        completeMigration(targetDefaults)
    }
}

// MARK: - Reading Legacy Data

private extension PersistentMigratorFromV2 {

    /// Extracts legacy data from UserDefaults.standard
    func extractLegacyData() -> LegacyDataV2? {
        guard let dict = MigrationUtilsV2.readLegacyUserDefaults() else {
            return nil
        }

        log("Found legacy data in UserDefaults")
        return extractLegacyData(from: dict)
    }
}

// MARK: - Extracting Legacy Values

private extension PersistentMigratorFromV2 {

    /// Extracts all legacy values from a source dictionary into a structured format
    func extractLegacyData(from dict: [String: Any]) -> LegacyDataV2? {
        let anonymousId = extractAnonymousId(from: dict)
        let (userId, traits) = extractUserIdAndTraits(from: dict)
        let sessionData = extractSessionData(from: dict)
        let applicationData = extractApplicationData(from: dict)

        // Return nil if no data was extracted
        if anonymousId == nil && userId == nil && traits == nil && sessionData == nil && applicationData == nil {
            return nil
        }

        return LegacyDataV2(
            anonymousId: anonymousId,
            userId: userId,
            traits: traits,
            sessionData: sessionData,
            applicationData: applicationData
        )
    }
    
    /// Extracts anonymous ID
    func extractAnonymousId(from dict: [String: Any]) -> String? {
        // Get anonymousId from the dedicated key
        guard let anonymousId = dict[PersistenceKeysV2.anonymousIdKey] as? String else {
            log("Anonymous ID not found in legacy storage")
            return nil
        }
        
        return anonymousId
    }

    /// Extracts user ID and traits from legacy storage
    /// In V2, userId is stored separately but also may exist in traits
    func extractUserIdAndTraits(from dict: [String: Any]) -> (userId: String?, traits: [String: Any]?) {
        // First try to get userId from the dedicated key
        var userId = dict[PersistenceKeysV2.legacyUserIdKey] as? String

        // Get traits if available
        guard let traits = dict[PersistenceKeysV2.legacyTraitsKey] as? [String: Any] else {
            return (userId, nil)
        }

        // If userId wasn't found in dedicated key, try to get it from traits
        if userId == nil {
            userId = traits[PersistenceKeysV2.traitsUserIdKey] as? String
        }

        return (userId, traits)
    }

    /// Extracts session-related data from legacy storage
    func extractSessionData(from dict: [String: Any]) -> SessionDataV2? {
        guard let sessionIdNumber = dict[PersistenceKeysV2.legacySessionId] as? NSNumber else {
            log("No active session details found.")
            return nil
        }

        let lastActivityTime = extractLastActivityTime(from: dict)
        let isManualSession = extractIsManualSession(from: dict)

        return SessionDataV2(
            sessionId: sessionIdNumber.uint64Value,
            lastActivityTime: lastActivityTime,
            isManualSession: isManualSession,
        )
    }

    /// Extracts and converts last activity time from legacy timestamp format
    func extractLastActivityTime(from dict: [String: Any]) -> UInt64? {
        guard let timestampNumber = dict[PersistenceKeysV2.legacyLastEventTimeStamp] as? NSNumber else {
            return nil
        }

        guard let convertedTime = MigrationUtilsV2.convertTimestampToSystemUptime(timestampNumber.doubleValue) else {
            log("Failed to convert lastEventTimeStamp - session timing may be affected")
            return nil
        }

        return convertedTime
    }

    /// Extracts manual session flag
    /// Note: V2 stores this directly as manual status (no inversion needed unlike V1)
    func extractIsManualSession(from dict: [String: Any]) -> Bool? {
        guard let isManualTrack = dict[PersistenceKeysV2.legacyIsSessionAutoTrackEnabled] as? NSNumber else {
            return nil
        }
        return isManualTrack.boolValue
    }

    /// Extracts application version and build from legacy storage
    func extractApplicationData(from dict: [String: Any]) -> ApplicationDataV2? {
        let version = dict[PersistenceKeysV2.legacyApplicationVersion] as? String
        let build = dict[PersistenceKeysV2.legacyApplicationBuild] as? String

        // Return nil if neither value exists
        guard version != nil || build != nil else {
            return nil
        }

        return ApplicationDataV2(version: version, build: build)
    }
}

// MARK: - Writing Migrated Data

private extension PersistentMigratorFromV2 {

    /// Writes all migrated data to Swift SDK storage
    func writeMigratedData(_ data: LegacyDataV2, to defaults: UserDefaults) {
        writeAnonymousId(data.anonymousId, to: defaults)
        writeUserId(data.userId, to: defaults)
        writeTraits(data.traits, to: defaults)
        writeSessionData(data.sessionData, to: defaults)
        writeApplicationData(data.applicationData, to: defaults)
    }

    /// Writes anonymous ID to Swift SDK storage
    func writeAnonymousId(_ anonymousId: String?, to defaults: UserDefaults) {
        guard let anonymousId = anonymousId else { return }

        defaults.set(anonymousId, forKey: PersistenceKeysV2.anonymousIdKey)
        log("Migrated anonymous Id")
    }
    
    /// Writes user ID to Swift SDK storage
    func writeUserId(_ userId: String?, to defaults: UserDefaults) {
        guard let userId = userId else { return }

        defaults.set(userId, forKey: PersistenceKeysV2.userIdKey)
        log("Migrated user ID")
    }

    /// Writes traits to Swift SDK storage (excluding userId, id and anonymousId)
    func writeTraits(_ traits: [String: Any]?, to defaults: UserDefaults) {
        guard var traits = traits else { return }

        // Remove IDs from traits - they are stored separately in Swift SDK
        traits.removeValue(forKey: PersistenceKeysV2.traitsAnonymousIdKey)
        traits.removeValue(forKey: PersistenceKeysV2.traitsUserIdKey)
        traits.removeValue(forKey: PersistenceKeysV2.traitsIdKey)

        guard !traits.isEmpty else {
            log("Traits empty after removing IDs - skipping traits migration")
            return
        }

        guard let encodedTraits = MigrationUtilsV2.encodeJSONDict(traits) else {
            log("Failed to encode traits - traits will not be migrated")
            return
        }

        defaults.set(encodedTraits, forKey: PersistenceKeysV2.traitsKey)
        log("Migrated user traits")
    }

    /// Writes session data to Swift SDK storage
    func writeSessionData(_ sessionData: SessionDataV2?, to defaults: UserDefaults) {
        guard let sessionData = sessionData else { return }

        writeSessionId(sessionData.sessionId, to: defaults)
        writeIsManualSession(sessionData.isManualSession, to: defaults)
        writeLastActivityTime(sessionData.lastActivityTime, to: defaults)
    }

    /// Writes session ID to Swift SDK storage
    func writeSessionId(_ sessionId: UInt64, to defaults: UserDefaults) {
        defaults.set(String(sessionId), forKey: PersistenceKeysV2.sessionId)
        log("Migrated session ID: \(sessionId)")
    }

    /// Writes manual session flag to Swift SDK storage
    func writeIsManualSession(_ isManualSession: Bool?, to defaults: UserDefaults) {
        guard let isManualSession = isManualSession else { return }

        defaults.set(isManualSession, forKey: PersistenceKeysV2.isManualSession)
        log("Migrated isManualSession: \(isManualSession)")
    }

    /// Writes last activity time to Swift SDK storage
    func writeLastActivityTime(_ lastActivityTime: UInt64?, to defaults: UserDefaults) {
        guard let lastActivityTime = lastActivityTime else { return }

        defaults.set(String(lastActivityTime), forKey: PersistenceKeysV2.lastActivityTime)
        log("Migrated lastActivityTime: \(lastActivityTime)")
    }

    /// Writes application data to Swift SDK storage
    func writeApplicationData(_ applicationData: ApplicationDataV2?, to defaults: UserDefaults) {
        guard let applicationData = applicationData else { return }

        writeApplicationVersion(applicationData.version, to: defaults)
        writeApplicationBuild(applicationData.build, to: defaults)
    }

    /// Writes application version to Swift SDK storage
    func writeApplicationVersion(_ version: String?, to defaults: UserDefaults) {
        guard let version = version else { return }

        defaults.set(version, forKey: PersistenceKeysV2.applicationVersion)
        log("Migrated application version: \(version)")
    }

    /// Writes application build to Swift SDK storage (converts String to Int)
    func writeApplicationBuild(_ build: String?, to defaults: UserDefaults) {
        guard let build = build, let buildNumber = Int(build) else { return }

        defaults.set(buildNumber, forKey: PersistenceKeysV2.applicationBuild)
        log("Migrated application build: \(buildNumber)")
    }
}

// MARK: - Migration Completion

private extension PersistentMigratorFromV2 {

    /// Completes migration by persisting changes and clearing legacy data
    func completeMigration(_ defaults: UserDefaults) {
        defaults.synchronize()
        MigrationUtilsV2.clearLegacyData()
        log("Migration completed successfully")
    }
}

// MARK: - Logging

private extension PersistentMigratorFromV2 {

    /// Logs a message with the PersistentMigratorFromV2 prefix
    func log(_ message: String) {
        print("PersistentMigratorFromV2: \(message)")
    }
}
