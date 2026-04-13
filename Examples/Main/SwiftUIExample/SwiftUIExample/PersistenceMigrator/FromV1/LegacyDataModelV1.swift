//
//  LegacyDataModelV1.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 23/12/25.
//

import Foundation

/// Holds all extracted legacy data in a structured format
struct LegacyDataV1 {
    let anonymousId: String?
    let userId: String?
    let traits: [String: Any]?
    let sessionData: SessionDataV1?
    let applicationData: ApplicationDataV1?

    /// Converts legacy data to a dictionary for public API
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]

        if let anonymousId = anonymousId {
            result["anonymousId"] = anonymousId
        }
        if let userId = userId {
            result["userId"] = userId
        }
        if let traits = traits {
            result["traits"] = traits
        }
        if let sessionData = sessionData {
            result["sessionId"] = sessionData.sessionId
            if let lastActivityTime = sessionData.lastActivityTime {
                result["lastActivityTime"] = lastActivityTime
            }
            if let isManualSession = sessionData.isManualSession {
                result["isManualSession"] = isManualSession
            }
        }
        if let applicationData = applicationData {
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

/// Holds session-related data extracted from legacy storage
struct SessionDataV1 {
    let sessionId: UInt64
    let lastActivityTime: UInt64?
    let isManualSession: Bool?
}

/// Holds application version data extracted from legacy storage
struct ApplicationDataV1 {
    let version: String?
    let build: String?
}
