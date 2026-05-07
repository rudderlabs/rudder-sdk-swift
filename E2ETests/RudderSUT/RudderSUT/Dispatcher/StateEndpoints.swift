//
//  StateEndpoints.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import RudderStackAnalytics

/**
 * StateEndpoints provides a utility layer to inspect and manipulate the internal state
 * of the RudderStack Analytics instance.
 *
 * It allows the test suite to query current identifiers (anonymousId, userId),
 * export the entire state as a dictionary, or restore the SDK state from a provided blob.
 * This is essential for verifying that the SDK maintains the correct state across
 * different test scenarios.
 */
enum StateEndpoints {

    // MARK: - Read

    static func read(key: String) -> Any? {
        let analytics = CommandDispatcher.shared.analytics
        switch key {
        case "anonymousId": return analytics?.anonymousId
        case "userId":      return analytics?.userId
        case "session":
            return [
                "sessionId": analytics?.sessionId.map { "\($0)" } as Any,
                "active":    analytics?.sessionId != nil
            ]
        default: return nil
        }
    }

    // MARK: - Export

    static func export() -> [String: Any] {
        let analytics = CommandDispatcher.shared.analytics
        return [
            "version":     1,
            "anonymousId": analytics?.anonymousId ?? "",
            "userId":      analytics?.userId ?? "",
            "traits":      analytics?.traits ?? [:],
            "sessionId":   analytics?.sessionId.map { "\($0)" } ?? ""
        ]
    }

    // MARK: - Restore

    static func restore(blob: [String: Any]) {
        guard let version = blob["version"] as? Int, version == 1 else {
            print("[StateEndpoints] Unsupported blob version, skipping restore")
            return
        }
        if let userId = blob["userId"] as? String, !userId.isEmpty {
            CommandDispatcher.shared.analytics?.identify(userId: userId,
                                                         traits: blob["traits"] as? [String: Any])
        }
    }
}
