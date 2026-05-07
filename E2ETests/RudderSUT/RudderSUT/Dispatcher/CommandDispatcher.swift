//
//  CommandDispatcher.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import RudderStackAnalytics

class CommandDispatcher {

    // MARK: - Shared

    static let shared = CommandDispatcher()
    private init() {}
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
        case "flush":        Analytics.shared.flush();       return ["status": "ok"]
        case "reset":        Analytics.shared.reset();       return ["status": "ok"]
        case "shutdown":     Analytics.shared.shutdown();    return ["status": "ok"]
        case "startSession": return handleStartSession(args)
        case "endSession":   Analytics.shared.endSession(); return ["status": "ok"]
        case "crash":        return handleCrash()
        case "nativeCrash":  return handleNativeCrash()
        default:             return ["error": "unknown command: \(cmd)"]
        }
    }
}

// MARK: - Handlers

extension CommandDispatcher {

    private func handleInit(_ args: [String: Any]) -> [String: Any] {
        let writeKey     = args["writeKey"] as? String ?? "test-key"
        let dataPlaneUrl = args["dataPlaneUrl"] as? String ?? "http://localhost:9090"

        let config = Configuration(writeKey: writeKey)
            .dataPlaneURL(dataPlaneUrl)

        if let trackLifecycle = args["trackLifecycleEvents"] as? Bool {
            config.trackLifecycleEvents(trackLifecycle)
        }
        if let sessionTimeout = args["sessionTimeout"] as? Int {
            config.sessionTimeout(sessionTimeout)
        }

        Analytics.initialize(configuration: config)
        return ["status": "ok"]
    }

    private func handleTrack(_ args: [String: Any]) -> [String: Any] {
        let name  = args["name"] as? String ?? ""
        let props = args["properties"] as? [String: Any]
        Analytics.shared.track(name: name, properties: props)
        return ["status": "ok"]
    }

    private func handleIdentify(_ args: [String: Any]) -> [String: Any] {
        let userId = args["userId"] as? String ?? ""
        let traits = args["traits"] as? [String: Any]
        Analytics.shared.identify(userId: userId, traits: traits)
        return ["status": "ok"]
    }

    private func handleScreen(_ args: [String: Any]) -> [String: Any] {
        let name     = args["name"] as? String ?? ""
        let category = args["category"] as? String
        let props    = args["properties"] as? [String: Any]
        Analytics.shared.screen(screenName: name, category: category, properties: props)
        return ["status": "ok"]
    }

    private func handleGroup(_ args: [String: Any]) -> [String: Any] {
        let groupId = args["groupId"] as? String ?? ""
        let traits  = args["traits"] as? [String: Any]
        Analytics.shared.group(groupId: groupId, traits: traits)
        return ["status": "ok"]
    }

    private func handleAlias(_ args: [String: Any]) -> [String: Any] {
        let newId = args["newId"] as? String ?? ""
        Analytics.shared.alias(newId: newId)
        return ["status": "ok"]
    }

    private func handleStartSession(_ args: [String: Any]) -> [String: Any] {
        let id = args["sessionId"] as? Int64
        Analytics.shared.startSession(sessionId: id)
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
