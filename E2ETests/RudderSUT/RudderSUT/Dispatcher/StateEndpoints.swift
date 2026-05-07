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
        let analytics = CommandDispatcher.shared.analytics
        switch key {
        case "anonymousId": return analytics?.anonymousId
        case "userId":      return analytics?.userId
        case "session":
            return [
                "sessionId": analytics?.sessionId as Any,
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
            "sessionId":   analytics?.sessionId ?? UInt64(0)
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
