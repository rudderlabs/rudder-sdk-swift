//
//  StateEndpoints.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import RudderStackAnalytics

enum StateEndpoints {

    // MARK: - Read

    static func read(key: String) -> Any? {
        switch key {
        case "anonymousId": return Analytics.shared.anonymousId
        case "userId":      return Analytics.shared.userId
        case "session":
            return [
                "sessionId": Analytics.shared.sessionId as Any,
                "active":    Analytics.shared.sessionId != nil
            ]
        default: return nil
        }
    }

    // MARK: - Export

    static func export() -> [String: Any] {
        [
            "version":     1,
            "anonymousId": Analytics.shared.anonymousId ?? "",
            "userId":      Analytics.shared.userId ?? "",
            "traits":      Analytics.shared.traits ?? [:],
            "sessionId":   Analytics.shared.sessionId ?? 0
        ]
    }

    // MARK: - Restore

    static func restore(blob: [String: Any]) {
        guard let version = blob["version"] as? Int, version == 1 else {
            print("[StateEndpoints] Unsupported blob version, skipping restore")
            return
        }
        if let userId = blob["userId"] as? String, !userId.isEmpty {
            Analytics.shared.identify(userId: userId,
                                      traits: blob["traits"] as? [String: Any])
        }
    }
}
