//
//  LegacyDataModelV2.swift
//  MultiRSA
//
//  Created by Satheesh Kannan on 24/12/25.
//

import Foundation

/// Holds all extracted legacy data from V2 SDK in a structured format
struct LegacyDataV2 {
    let anonymousId: String?
    let userId: String?
    let traits: [String: Any]?
    let sessionData: SessionDataV2?
    let applicationData: ApplicationDataV2?

    /// Converts legacy data to a dictionary for public API
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]

        if let anonymousId {
            result["anonymousId"] = anonymousId
        }
        if let userId {
            result["userId"] = userId
        }
        if let traits {
            result["traits"] = traits
        }
        if let sessionData {
            result["sessionId"] = sessionData.sessionId
            if let lastActivityTime = sessionData.lastActivityTime {
                result["lastActivityTime"] = lastActivityTime
            }
            if let isManualSession = sessionData.isManualSession {
                result["isManualSession"] = isManualSession
            }
        }
        if let applicationData {
            if let version = applicationData.version {
                result["applicationVersion"] = version
            }
            if let build = applicationData.build {
                result["applicationBuild"] = build
            }
        }

        return result
    }
}

/// Holds session-related data extracted from legacy V2 storage
struct SessionDataV2 {
    let sessionId: UInt64
    let lastActivityTime: UInt64?
    let isManualSession: Bool?
}

/// Holds application version data extracted from legacy V2 storage
struct ApplicationDataV2 {
    let version: String?
    let build: String?
}
