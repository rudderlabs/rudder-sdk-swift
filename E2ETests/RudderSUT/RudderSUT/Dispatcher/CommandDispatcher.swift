//
//  CommandDispatcher.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation
import UIKit
import RudderStackAnalytics

/**
 * CommandDispatcher acts as a bridge between incoming test commands and the RudderStack Analytics SDK.
 * It follows the singleton pattern to provide a centralized point for executing analytics operations
 * such as initialization, event tracking, user identification, and session management.
 *
 * Each command received through the `dispatch` method is routed to a specific handler that
 * translates test arguments into SDK-compatible calls.
 */
class CommandDispatcher {

    // MARK: - Shared

    static let shared = CommandDispatcher()
    private init() {}

    // MARK: - Properties

    private(set) var analytics: Analytics?
    private var sseStream: SSEStream?
}

// MARK: - Configuration

extension CommandDispatcher {

    func configure(sseStream: SSEStream) {
        self.sseStream = sseStream
    }
}

// MARK: - Dispatch

extension CommandDispatcher {

    func dispatch(cmd: String, args: [String: Any]) -> [String: Any] {
        switch cmd {
        case "init":         return handleInit(args)
        case "track":        return handleTrack(args)
        case "identify":     return handleIdentify(args)
        case "screen":       return handleScreen(args)
        case "group":        return handleGroup(args)
        case "alias":        return handleAlias(args)
        case "flush":        analytics?.flush();     return ["status": "ok"]
        case "reset":        return handleReset(args)
        case "shutdown":     analytics?.shutdown();    return ["status": "ok"]
        case "startSession": return handleStartSession(args)
        case "endSession":   analytics?.endSession(); return ["status": "ok"]
        case "openURL":      return handleOpenURL(args)
        case "crash":        return handleCrash()
        case "nativeCrash":  return handleNativeCrash()
        default:             return ["error": "unknown command: \(cmd)"]
        }
    }
}

// MARK: - Handlers

extension CommandDispatcher {

    private func handleInit(_ args: [String: Any]) -> [String: Any] {
        let writeKey       = args["writeKey"] as? String ?? "test-key"
        let dataPlaneUrl   = args["dataPlaneUrl"] as? String ?? "http://localhost:9090"
        let trackLifecycle = args["trackLifecycleEvents"] as? Bool ?? false

        var sessionConfig = SessionConfiguration()
        if let sessionTimeout = args["sessionTimeout"] as? Int {
            sessionConfig = SessionConfiguration(sessionTimeoutInMillis: UInt64(sessionTimeout))
        }

        let config = Configuration(
            writeKey: writeKey,
            dataPlaneUrl: dataPlaneUrl,
            trackApplicationLifecycleEvents: trackLifecycle,
            sessionConfiguration: sessionConfig
        )

        analytics = Analytics(configuration: config)
        if let stream = sseStream {
            analytics?.add(plugin: ObserverPlugin(stream: stream))
        }
        return ["status": "ok"]
    }

    private func handleTrack(_ args: [String: Any]) -> [String: Any] {
        let name  = args["name"] as? String ?? ""
        let props = args["properties"] as? [String: Any]
        analytics?.track(name: name, properties: props, options: buildOption(args))
        return ["status": "ok"]
    }

    private func handleIdentify(_ args: [String: Any]) -> [String: Any] {
        let userId = args["userId"] as? String
        let traits = args["traits"] as? [String: Any]
        analytics?.identify(userId: userId, traits: traits, options: buildOption(args))
        return ["status": "ok"]
    }

    private func handleScreen(_ args: [String: Any]) -> [String: Any] {
        let name     = args["name"] as? String ?? ""
        let category = args["category"] as? String
        let props    = args["properties"] as? [String: Any]
        analytics?.screen(screenName: name, category: category, properties: props, options: buildOption(args))
        return ["status": "ok"]
    }

    private func handleGroup(_ args: [String: Any]) -> [String: Any] {
        let groupId = args["groupId"] as? String ?? ""
        let traits  = args["traits"] as? [String: Any]
        analytics?.group(groupId: groupId, traits: traits, options: buildOption(args))
        return ["status": "ok"]
    }

    private func handleAlias(_ args: [String: Any]) -> [String: Any] {
        let newId      = args["newId"] as? String ?? ""
        let previousId = args["previousId"] as? String
        analytics?.alias(newId: newId, previousId: previousId, options: buildOption(args))
        return ["status": "ok"]
    }

    private func handleReset(_ args: [String: Any]) -> [String: Any] {
        let entries = ResetEntries(
            anonymousId: args["anonymousId"] as? Bool ?? true,
            userId:      args["userId"]      as? Bool ?? true,
            traits:      args["traits"]      as? Bool ?? true,
            session:     args["session"]     as? Bool ?? true
        )
        analytics?.reset(options: ResetOptions(entries: entries))
        return ["status": "ok"]
    }

    private func buildOption(_ args: [String: Any]) -> RudderOption? {
        guard let dict = args["options"] as? [String: Any] else { return nil }
        let integrations = dict["integrations"] as? [String: Any]
        let customContext = dict["customContext"] as? [String: Any]
        let externalIds = (dict["externalIds"] as? [[String: String]])?.compactMap { d -> ExternalId? in
            guard let type = d["type"], let id = d["id"] else { return nil }
            return ExternalId(type: type, id: id)
        }
        return RudderOption(integrations: integrations, customContext: customContext, externalIds: externalIds)
    }

    private func handleStartSession(_ args: [String: Any]) -> [String: Any] {
        let id = (args["sessionId"] as? Int).map { UInt64($0) }
        analytics?.startSession(sessionId: id)
        return ["status": "ok"]
    }

    private func handleOpenURL(_ args: [String: Any]) -> [String: Any] {
        guard let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            return ["error": "invalid url"]
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
        return ["status": "ok"]
    }

    private func handleCrash() -> [String: Any] {
        DispatchQueue.main.async { fatalError("intentional test crash") }
        return ["status": "crashing"]
    }

    private func handleNativeCrash() -> [String: Any] {
        DispatchQueue.main.async {
            let ptr: UnsafeMutablePointer<Int>? = nil
            ptr!.pointee = 0
        }
        return ["status": "crashing"]
    }
}
