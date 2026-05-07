//
//  Step.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

enum Step {

    // MARK: - Init / Teardown
    case initialize(writeKey: String, dataPlaneUrl: String, options: [String: Any] = [:])
    case reset(options: [String: Bool]? = nil)
    case flush
    case shutdown

    // MARK: - Events
    case track(name: String, properties: [String: Any]? = nil, options: [String: Any]? = nil)
    case screen(name: String, category: String? = nil, properties: [String: Any]? = nil, options: [String: Any]? = nil)
    case identify(userId: String? = nil, traits: [String: Any]? = nil, options: [String: Any]? = nil)
    case group(groupId: String, traits: [String: Any]? = nil, options: [String: Any]? = nil)
    case alias(newId: String, previousId: String? = nil, options: [String: Any]? = nil)

    // MARK: - Session
    case startSession(id: UInt64? = nil)
    case endSession

    // MARK: - Lifecycle
    case background
    case foreground
    case kill
    case coldStart

    // MARK: - System State
    case networkOffline
    case networkOnline
    case deepLink(url: String)
    case localeChange(locale: String)
    case crash(kind: CrashKind)

    // MARK: - Assertions
    case waitForBatch(timeout: TimeInterval = 5)
    case waitForEvent(name: String, timeout: TimeInterval = 5, predicate: (([String: Any]) -> Bool)? = nil)
    case assertNoEvent(name: String, window: TimeInterval = 3)
    case assertState(key: String, expected: Any)

    // MARK: - State Management
    case snapshotState
    case importState(blob: [String: Any])

    // MARK: - Nested Types
    enum CrashKind { case swift, native }
}

// MARK: - JSON Decoding

extension Step {

    static func decode(_ dict: [String: Any]) -> Step? {
        guard let type = dict["type"] as? String else { return nil }
        switch type {
        case "track":
            return .track(name: dict["name"] as? String ?? "",
                          properties: dict["properties"] as? [String: Any],
                          options: dict["options"] as? [String: Any])
        case "identify":
            return .identify(userId: dict["userId"] as? String,
                             traits: dict["traits"] as? [String: Any],
                             options: dict["options"] as? [String: Any])
        case "screen":
            return .screen(name: dict["name"] as? String ?? "",
                           category: dict["category"] as? String,
                           properties: dict["properties"] as? [String: Any],
                           options: dict["options"] as? [String: Any])
        case "group":
            return .group(groupId: dict["groupId"] as? String ?? "",
                          traits: dict["traits"] as? [String: Any],
                          options: dict["options"] as? [String: Any])
        case "alias":
            return .alias(newId: dict["newId"] as? String ?? "",
                          previousId: dict["previousId"] as? String,
                          options: dict["options"] as? [String: Any])
        case "reset":
            return .reset(options: dict["options"] as? [String: Bool])
        case "flush":          return .flush
        case "background":     return .background
        case "foreground":     return .foreground
        case "kill":           return .kill
        case "coldStart":      return .coldStart
        case "networkOffline": return .networkOffline
        case "networkOnline":  return .networkOnline
        case "waitForBatch":
            return .waitForBatch(timeout: dict["timeout"] as? TimeInterval ?? 5)
        case "assertNoEvent":
            return .assertNoEvent(name: dict["name"] as? String ?? "",
                                  window: dict["window"] as? TimeInterval ?? 3)
        default: return nil
        }
    }
}
