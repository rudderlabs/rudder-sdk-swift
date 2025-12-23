//
//  PersistenceMigrator.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 20/12/25.
//

import Foundation

// MARK: - PersistenceMigrator

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
 let migrator = PersistenceMigrator(writeKey: "your_write_key")
 migrator.restorePersistence()

 // Then initialize the Swift SDK
 let config = Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
 let analytics = Analytics(configuration: config)
 ```

 ## Inspecting Legacy Data

 Use `readPersistence()` to inspect what data will be migrated:

 ```swift
 let migrator = PersistenceMigrator(writeKey: "your_write_key")
 if let legacyData = migrator.readPersistence() {
     print("Data to migrate: \(legacyData)")
 }
 ```
 */
public final class PersistenceMigrator {

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
        guard !MigrationUtils.isSwiftDefaultsAvailable(writeKey) else {
            log("Swift SDK storage already exists, skipping migration")
            return
        }

        guard let legacyData = extractLegacyData() else {
            log("No legacy data found, skipping migration")
            return
        }

        guard let targetDefaults = MigrationUtils.rudderSwiftDefaults(writeKey) else {
            log("Failed to access Swift SDK storage for writeKey: \(writeKey)")
            return
        }

        log("Starting migration for writeKey: \(writeKey)")

        writeMigratedData(legacyData, to: targetDefaults)
        completeMigration(targetDefaults)
    }
}

// MARK: - Reading Legacy Data

private extension PersistenceMigrator {

    /// Extracts legacy data from plist file (preferred) or UserDefaults (fallback)
    func extractLegacyData() -> LegacyData? {
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
    func readFromPlist() -> LegacyData? {
        guard let dict = MigrationUtils.readPlist() else {
            return nil
        }
        return extractLegacyData(from: dict)
    }

    /// Reads and extracts legacy data from UserDefaults
    func readFromUserDefaults() -> LegacyData? {
        guard let dict = MigrationUtils.readLegacyUserDefaults() else {
            return nil
        }
        return extractLegacyData(from: dict)
    }
}

// MARK: - Extracting Legacy Values

private extension PersistenceMigrator {

    /// Extracts all legacy values from a source dictionary into a structured format
    func extractLegacyData(from dict: [String: Any]) -> LegacyData? {
        let anonymousId = extractAnonymousId(from: dict)
        let (userId, traits) = extractUserIdAndTraits(from: dict)
        let sessionData = extractSessionData(from: dict)
        let applicationData = extractApplicationData(from: dict)

        // Return nil if no data was extracted
        if anonymousId == nil && userId == nil && traits == nil && sessionData == nil && applicationData == nil {
            return nil
        }

        return LegacyData(
            anonymousId: anonymousId,
            userId: userId,
            traits: traits,
            sessionData: sessionData,
            applicationData: applicationData
        )
    }

    /// Extracts anonymous ID from legacy storage
    func extractAnonymousId(from dict: [String: Any]) -> String? {
        return dict[PersistenceKeys.legacyAnonymousIdKey] as? String
    }

    /// Extracts user ID and traits from legacy storage
    /// Note: User ID is stored within the traits JSON in the legacy SDK
    func extractUserIdAndTraits(from dict: [String: Any]) -> (userId: String?, traits: [String: Any]?) {
        guard let traitsJson = dict[PersistenceKeys.legacyTraitsKey] as? String else {
            return (nil, nil)
        }

        guard let traits = MigrationUtils.decodeJSONDict(from: traitsJson) else {
            log("Failed to decode traits JSON - userId and traits will not be migrated")
            return (nil, nil)
        }

        let userId = traits[PersistenceKeys.legacyUserIdKey] as? String
        return (userId, traits)
    }

    /// Extracts session-related data from legacy storage
    func extractSessionData(from dict: [String: Any]) -> SessionData? {
        guard let sessionIdNumber = dict[PersistenceKeys.legacySessionId] as? NSNumber else {
            log("No active session details found.")
            return nil
        }
        
        guard let lastActivityTime = extractLastActivityTime(from: dict) else {
            log("Unable to extract last activity time from the legacy value. Aborting session details migration.")
            return nil
        }

        let isManualSession = extractIsManualSession(from: dict)

        return SessionData(
            sessionId: sessionIdNumber.uint64Value,
            lastActivityTime: lastActivityTime,
            isManualSession: isManualSession
        )
    }

    /// Extracts and converts last activity time from legacy timestamp format
    func extractLastActivityTime(from dict: [String: Any]) -> UInt64? {
        guard let timestampNumber = dict[PersistenceKeys.legacyLastEventTimeStamp] as? NSNumber else {
            return nil
        }

        guard let convertedTime = MigrationUtils.convertTimestampToSystemUptime(timestampNumber.doubleValue) else {
            log("Failed to convert lastEventTimeStamp - session timing may be affected")
            return nil
        }

        return convertedTime
    }

    /// Extracts and inverts the auto-track flag to get manual session setting
    func extractIsManualSession(from dict: [String: Any]) -> Bool? {
        guard let isAutoTrack = dict[PersistenceKeys.legacyIsSessionAutoTrackEnabled] as? NSNumber else {
            return nil
        }
        return !isAutoTrack.boolValue
    }

    /// Extracts application version and build from legacy storage
    func extractApplicationData(from dict: [String: Any]) -> ApplicationData? {
        let version = dict[PersistenceKeys.legacyApplicationVersion] as? String
        let build = dict[PersistenceKeys.legacyApplicationBuild] as? String

        // Return nil if neither value exists
        guard version != nil || build != nil else {
            return nil
        }

        return ApplicationData(version: version, build: build)
    }
}

// MARK: - Writing Migrated Data

private extension PersistenceMigrator {

    /// Writes all migrated data to Swift SDK storage
    func writeMigratedData(_ data: LegacyData, to defaults: UserDefaults) {
        writeAnonymousId(data.anonymousId, to: defaults)
        writeUserId(data.userId, to: defaults)
        writeTraits(data.traits, to: defaults)
        writeSessionData(data.sessionData, to: defaults)
        writeApplicationData(data.applicationData, to: defaults)
    }

    /// Writes anonymous ID to Swift SDK storage
    func writeAnonymousId(_ anonymousId: String?, to defaults: UserDefaults) {
        guard let anonymousId = anonymousId else { return }

        defaults.set(anonymousId, forKey: PersistenceKeys.anonymousIdKey)
        log("Migrated anonymous ID")
    }

    /// Writes user ID to Swift SDK storage
    func writeUserId(_ userId: String?, to defaults: UserDefaults) {
        guard let userId = userId else { return }

        defaults.set(userId, forKey: PersistenceKeys.userIdKey)
        log("Migrated user ID")
    }

    /// Writes traits to Swift SDK storage (excluding userId and anonymousId which are stored separately)
    func writeTraits(_ traits: [String: Any]?, to defaults: UserDefaults) {
        guard var traits = traits else { return }

        // Remove IDs from traits - they are stored separately in Swift SDK
        traits.removeValue(forKey: PersistenceKeys.traitsAnonymousIdKey)
        traits.removeValue(forKey: PersistenceKeys.traitsUserIdKey)

        guard let encodedTraits = MigrationUtils.encodeJSONDict(traits) else {
            log("Failed to encode traits - traits will not be migrated")
            return
        }

        defaults.set(encodedTraits, forKey: PersistenceKeys.traitsKey)
        log("Migrated user traits")
    }

    /// Writes session data to Swift SDK storage
    func writeSessionData(_ sessionData: SessionData?, to defaults: UserDefaults) {
        guard let sessionData = sessionData else { return }

        writeSessionId(sessionData.sessionId, to: defaults)
        writeIsManualSession(sessionData.isManualSession, to: defaults)
        writeLastActivityTime(sessionData.lastActivityTime, to: defaults)
        writeSessionStartFlag(to: defaults)
    }

    /// Writes session ID to Swift SDK storage
    func writeSessionId(_ sessionId: UInt64, to defaults: UserDefaults) {
        defaults.set(String(sessionId), forKey: PersistenceKeys.sessionId)
        log("Migrated session ID: \(sessionId)")
    }

    /// Writes manual session flag to Swift SDK storage
    func writeIsManualSession(_ isManualSession: Bool?, to defaults: UserDefaults) {
        guard let isManualSession = isManualSession else { return }

        defaults.set(isManualSession, forKey: PersistenceKeys.isManualSession)
        log("Migrated isManualSession: \(isManualSession)")
    }

    /// Writes last activity time to Swift SDK storage
    func writeLastActivityTime(_ lastActivityTime: UInt64?, to defaults: UserDefaults) {
        guard let lastActivityTime = lastActivityTime else { return }

        defaults.set(String(lastActivityTime), forKey: PersistenceKeys.lastActivityTime)
        log("Migrated lastActivityTime: \(lastActivityTime)")
    }

    /// Marks session as not starting (since we're restoring an existing session)
    func writeSessionStartFlag(to defaults: UserDefaults) {
        defaults.set(false, forKey: PersistenceKeys.isSessionStart)
        log("Set isSessionStart to false")
    }

    /// Writes application data to Swift SDK storage
    func writeApplicationData(_ applicationData: ApplicationData?, to defaults: UserDefaults) {
        guard let applicationData = applicationData else { return }

        writeApplicationVersion(applicationData.version, to: defaults)
        writeApplicationBuild(applicationData.build, to: defaults)
    }

    /// Writes application version to Swift SDK storage
    func writeApplicationVersion(_ version: String?, to defaults: UserDefaults) {
        guard let version = version else { return }

        defaults.set(version, forKey: PersistenceKeys.applicationVersion)
        log("Migrated application version: \(version)")
    }

    /// Writes application build to Swift SDK storage (converts String to Int)
    func writeApplicationBuild(_ build: String?, to defaults: UserDefaults) {
        guard let build = build, let buildNumber = Int(build) else { return }

        defaults.set(buildNumber, forKey: PersistenceKeys.applicationBuild)
        log("Migrated application build: \(buildNumber)")
    }
}

// MARK: - Migration Completion

private extension PersistenceMigrator {

    /// Completes migration by persisting changes and clearing legacy data
    func completeMigration(_ defaults: UserDefaults) {
        defaults.synchronize()
        MigrationUtils.clearLegacyData()
        log("Migration completed successfully")
    }
}

// MARK: - Logging

private extension PersistenceMigrator {

    /// Logs a message with the PersistenceMigrator prefix
    func log(_ message: String) {
        print("PersistenceMigrator: \(message)")
    }
}
