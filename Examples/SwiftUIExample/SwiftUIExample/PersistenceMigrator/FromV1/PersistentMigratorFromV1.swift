//
//  PersistentMigratorFromV1.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 20/12/25.
//

import Foundation

// MARK: - PersistentMigratorFromV1

/**
 Migrates persistence data from the legacy Rudder iOS SDK (V1) to the new Swift SDK.

 This class reads data stored by the legacy SDK (from plist files or UserDefaults) and writes it
 to the Swift SDK's UserDefaults suite. It handles migration of:
 - Anonymous ID
 - User ID
 - User traits
 - Session data
 - Application version and build

 ## Usage

 Call `restorePersistence()` once during app initialization, **before** initializing the RudderStack Swift SDK:

 ```swift
 // In AppDelegate or App init
 let migrator = PersistentMigratorFromV1(writeKey: "your_write_key")
 migrator.restorePersistence()

 // Then initialize the Swift SDK
 let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
 let analytics = Analytics(configuration: config)
 ```

 ## Inspecting Legacy Data

 Use `readPersistence()` to inspect what data will be migrated:

 ```swift
 let migrator = PersistentMigratorFromV1(writeKey: "your_write_key")
 if let legacyData = migrator.readPersistence() {
     print("Data to migrate: \(legacyData)")
 }
 ```
 */
public final class PersistentMigratorFromV1 {

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
     Reads legacy SDK persistence data without performing migration.

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
     Restores legacy SDK persistence data to the Swift SDK.

     This method:
     1. Checks if Swift SDK storage already exists (aborts if so)
     2. Reads legacy data from plist file or UserDefaults
     3. Transforms and writes data to the Swift SDK's storage
     4. Clears legacy data after successful migration

     Safe to call multiple times - returns early if Swift SDK data or no legacy data exists.
     */
    public func restorePersistence() {
        guard !MigrationUtilsV1.isSwiftDefaultsAvailable(writeKey) else {
            log("Swift SDK storage already exists, skipping migration")
            return
        }

        guard let legacyData = extractLegacyData() else {
            log("No legacy data found, skipping migration")
            return
        }

        guard let targetDefaults = MigrationUtilsV1.rudderSwiftDefaults(writeKey) else {
            log("Failed to access Swift SDK storage for writeKey: \(writeKey)")
            return
        }

        log("Starting migration for writeKey: \(writeKey)")

        writeMigratedData(legacyData, to: targetDefaults)
        completeMigration(targetDefaults)
    }
}

// MARK: - Reading Legacy Data

private extension PersistentMigratorFromV1 {

    /// Extracts legacy data from plist file (preferred) or UserDefaults (fallback)
    func extractLegacyData() -> LegacyDataV1? {
        if let plistData = readFromPlist() {
            log("Found legacy data in plist file")
            return plistData
        }

        if let userDefaultsData = readFromUserDefaults() {
            log("Found legacy data in UserDefaults")
            return userDefaultsData
        }

        return nil
    }

    /// Reads and extracts legacy data from plist file
    func readFromPlist() -> LegacyDataV1? {
        guard let dict = MigrationUtilsV1.readPlist() else {
            return nil
        }
        return extractLegacyData(from: dict)
    }

    /// Reads and extracts legacy data from UserDefaults
    func readFromUserDefaults() -> LegacyDataV1? {
        guard let dict = MigrationUtilsV1.readLegacyUserDefaults() else {
            return nil
        }
        return extractLegacyData(from: dict)
    }
}

// MARK: - Extracting Legacy Values

private extension PersistentMigratorFromV1 {

    /// Extracts all legacy values from a source dictionary into a structured format
    func extractLegacyData(from dict: [String: Any]) -> LegacyDataV1? {
        let anonymousId = extractAnonymousId(from: dict)
        let (userId, traits) = extractUserIdAndTraits(from: dict)
        let sessionData = extractSessionData(from: dict)
        let applicationData = extractApplicationData(from: dict)

        // Return nil if no data was extracted
        if anonymousId == nil && userId == nil && traits == nil && sessionData == nil && applicationData == nil {
            return nil
        }

        return LegacyDataV1(
            anonymousId: anonymousId,
            userId: userId,
            traits: traits,
            sessionData: sessionData,
            applicationData: applicationData
        )
    }

    /// Extracts anonymous ID from legacy storage
    func extractAnonymousId(from dict: [String: Any]) -> String? {
        return dict[PersistenceKeysV1.legacyAnonymousIdKey] as? String
    }

    /// Extracts user ID and traits from legacy storage
    /// Note: User ID is stored within the traits JSON in the legacy SDK
    func extractUserIdAndTraits(from dict: [String: Any]) -> (userId: String?, traits: [String: Any]?) {
        guard let traitsJson = dict[PersistenceKeysV1.legacyTraitsKey] as? String else {
            return (nil, nil)
        }

        guard let traits = MigrationUtilsV1.decodeJSONDict(from: traitsJson) else {
            log("Failed to decode traits JSON - userId and traits will not be migrated")
            return (nil, nil)
        }

        let userId = traits[PersistenceKeysV1.legacyUserIdKey] as? String
        return (userId, traits)
    }

    /// Extracts session-related data from legacy storage
    func extractSessionData(from dict: [String: Any]) -> SessionDataV1? {
        guard let sessionIdNumber = dict[PersistenceKeysV1.legacySessionId] as? NSNumber else {
            log("No active session details found.")
            return nil
        }
        
        guard let lastActivityTime = extractLastActivityTime(from: dict) else {
            log("Unable to extract last activity time from the legacy value. Aborting session details migration.")
            return nil
        }

        let isManualSession = extractIsManualSession(from: dict)

        return SessionDataV1(
            sessionId: sessionIdNumber.uint64Value,
            lastActivityTime: lastActivityTime,
            isManualSession: isManualSession
        )
    }

    /// Extracts and converts last activity time from legacy timestamp format
    func extractLastActivityTime(from dict: [String: Any]) -> UInt64? {
        guard let timestampNumber = dict[PersistenceKeysV1.legacyLastEventTimeStamp] as? NSNumber else {
            return nil
        }

        guard let convertedTime = MigrationUtilsV1.convertTimestampToSystemUptime(timestampNumber.doubleValue) else {
            log("Failed to convert lastEventTimeStamp - session timing may be affected")
            return nil
        }

        return convertedTime
    }

    /// Extracts and inverts the auto-track flag to get manual session setting
    func extractIsManualSession(from dict: [String: Any]) -> Bool? {
        guard let isAutoTrack = dict[PersistenceKeysV1.legacyIsSessionAutoTrackEnabled] as? NSNumber else {
            return nil
        }
        return !isAutoTrack.boolValue
    }

    /// Extracts application version and build from legacy storage
    func extractApplicationData(from dict: [String: Any]) -> ApplicationDataV1? {
        let version = dict[PersistenceKeysV1.legacyApplicationVersion] as? String
        let build = dict[PersistenceKeysV1.legacyApplicationBuild] as? String

        // Return nil if neither value exists
        guard version != nil || build != nil else {
            return nil
        }

        return ApplicationDataV1(version: version, build: build)
    }
}

// MARK: - Writing Migrated Data

private extension PersistentMigratorFromV1 {

    /// Writes all migrated data to Swift SDK storage
    func writeMigratedData(_ data: LegacyDataV1, to defaults: UserDefaults) {
        writeAnonymousId(data.anonymousId, to: defaults)
        writeUserId(data.userId, to: defaults)
        writeTraits(data.traits, to: defaults)
        writeSessionData(data.sessionData, to: defaults)
        writeApplicationData(data.applicationData, to: defaults)
    }

    /// Writes anonymous ID to Swift SDK storage
    func writeAnonymousId(_ anonymousId: String?, to defaults: UserDefaults) {
        guard let anonymousId = anonymousId else { return }

        defaults.set(anonymousId, forKey: PersistenceKeysV1.anonymousIdKey)
        log("Migrated anonymous ID")
    }

    /// Writes user ID to Swift SDK storage
    func writeUserId(_ userId: String?, to defaults: UserDefaults) {
        guard let userId = userId else { return }

        defaults.set(userId, forKey: PersistenceKeysV1.userIdKey)
        log("Migrated user ID")
    }

    /// Writes traits to Swift SDK storage (excluding userId and anonymousId which are stored separately)
    func writeTraits(_ traits: [String: Any]?, to defaults: UserDefaults) {
        guard var traits = traits else { return }

        // Remove IDs from traits - they are stored separately in Swift SDK
        traits.removeValue(forKey: PersistenceKeysV1.traitsAnonymousIdKey)
        traits.removeValue(forKey: PersistenceKeysV1.traitsUserIdKey)

        guard let encodedTraits = MigrationUtilsV1.encodeJSONDict(traits) else {
            log("Failed to encode traits - traits will not be migrated")
            return
        }

        defaults.set(encodedTraits, forKey: PersistenceKeysV1.traitsKey)
        log("Migrated user traits")
    }

    /// Writes session data to Swift SDK storage
    func writeSessionData(_ sessionData: SessionDataV1?, to defaults: UserDefaults) {
        guard let sessionData = sessionData else { return }

        writeSessionId(sessionData.sessionId, to: defaults)
        writeIsManualSession(sessionData.isManualSession, to: defaults)
        writeLastActivityTime(sessionData.lastActivityTime, to: defaults)
        writeSessionStartFlag(to: defaults)
    }

    /// Writes session ID to Swift SDK storage
    func writeSessionId(_ sessionId: UInt64, to defaults: UserDefaults) {
        defaults.set(String(sessionId), forKey: PersistenceKeysV1.sessionId)
        log("Migrated session ID: \(sessionId)")
    }

    /// Writes manual session flag to Swift SDK storage
    func writeIsManualSession(_ isManualSession: Bool?, to defaults: UserDefaults) {
        guard let isManualSession = isManualSession else { return }

        defaults.set(isManualSession, forKey: PersistenceKeysV1.isManualSession)
        log("Migrated isManualSession: \(isManualSession)")
    }

    /// Writes last activity time to Swift SDK storage
    func writeLastActivityTime(_ lastActivityTime: UInt64?, to defaults: UserDefaults) {
        guard let lastActivityTime = lastActivityTime else { return }

        defaults.set(String(lastActivityTime), forKey: PersistenceKeysV1.lastActivityTime)
        log("Migrated lastActivityTime: \(lastActivityTime)")
    }

    /// Marks session as not starting (since we're restoring an existing session)
    func writeSessionStartFlag(to defaults: UserDefaults) {
        defaults.set(false, forKey: PersistenceKeysV1.isSessionStart)
        log("Set isSessionStart to false")
    }

    /// Writes application data to Swift SDK storage
    func writeApplicationData(_ applicationData: ApplicationDataV1?, to defaults: UserDefaults) {
        guard let applicationData = applicationData else { return }

        writeApplicationVersion(applicationData.version, to: defaults)
        writeApplicationBuild(applicationData.build, to: defaults)
    }

    /// Writes application version to Swift SDK storage
    func writeApplicationVersion(_ version: String?, to defaults: UserDefaults) {
        guard let version = version else { return }

        defaults.set(version, forKey: PersistenceKeysV1.applicationVersion)
        log("Migrated application version: \(version)")
    }

    /// Writes application build to Swift SDK storage (converts String to Int)
    func writeApplicationBuild(_ build: String?, to defaults: UserDefaults) {
        guard let build = build, let buildNumber = Int(build) else { return }

        defaults.set(buildNumber, forKey: PersistenceKeysV1.applicationBuild)
        log("Migrated application build: \(buildNumber)")
    }
}

// MARK: - Migration Completion

private extension PersistentMigratorFromV1 {

    /// Completes migration by persisting changes and clearing legacy data
    func completeMigration(_ defaults: UserDefaults) {
        defaults.synchronize()
        MigrationUtilsV1.clearLegacyData()
        log("Migration completed successfully")
    }
}

// MARK: - Logging

private extension PersistentMigratorFromV1 {

    /// Logs a message with the PersistentMigratorFromV1 prefix
    func log(_ message: String) {
        print("PersistentMigratorFromV1: \(message)")
    }
}
