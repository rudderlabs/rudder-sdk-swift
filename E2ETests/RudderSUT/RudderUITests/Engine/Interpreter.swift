//
//  Interpreter.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

class Interpreter {

    // MARK: - Properties

    let app: XCUIApplication
    var sutClient: any SUTClientProtocol
    let mockServer: MockServer
    let lifecycle: LifecycleHelper
    var savedStateBlob: [String: Any]?
    private(set) var executedSteps: [Step] = []

    // MARK: - Init

    init(app: XCUIApplication, sutClient: any SUTClientProtocol, mockServer: MockServer) {
        self.app        = app
        self.sutClient  = sutClient
        self.mockServer = mockServer
        self.lifecycle  = LifecycleHelper(app: app)
    }
}

// MARK: - Init (Convenience)

extension Interpreter {

    convenience init(app: XCUIApplication, sutPort: UInt16, mockServer: MockServer) {
        self.init(app: app,
                  sutClient: SUTClient(baseURL: "http://127.0.0.1:\(sutPort)"),
                  mockServer: mockServer)
    }
}

// MARK: - Execution

extension Interpreter {

    func run(_ steps: [Step]) throws {
        for step in steps { try execute(step) }
    }

    func execute(_ step: Step) throws {
        executedSteps.append(step)
        switch step {

        case let .initialize(writeKey, dataPlaneUrl, options):
            var args: [String: Any] = ["writeKey": writeKey, "dataPlaneUrl": dataPlaneUrl]
            args.merge(options) { _, new in new }
            try sutClient.post("/command", body: ["cmd": "init", "args": args])

        case let .reset(options):
            var body: [String: Any] = ["cmd": "reset"]
            if let opts = options { body["args"] = opts }
            try sutClient.post("/command", body: body)

        case .flush:
            try sutClient.post("/command", body: ["cmd": "flush"])

        case .shutdown:
            try sutClient.post("/command", body: ["cmd": "shutdown"])

        case let .track(name, properties, options):
            var args: [String: Any] = ["name": name]
            if let p = properties { args["properties"] = p }
            if let o = options    { args["options"] = o }
            try sutClient.post("/command", body: ["cmd": "track", "args": args])

        case let .identify(userId, traits, options):
            var args: [String: Any] = [:]
            if let u = userId  { args["userId"] = u }
            if let t = traits  { args["traits"] = t }
            if let o = options { args["options"] = o }
            try sutClient.post("/command", body: ["cmd": "identify", "args": args])

        case let .screen(name, category, properties, options):
            var args: [String: Any] = ["name": name]
            if let c = category   { args["category"] = c }
            if let p = properties { args["properties"] = p }
            if let o = options    { args["options"] = o }
            try sutClient.post("/command", body: ["cmd": "screen", "args": args])

        case let .group(groupId, traits, options):
            var args: [String: Any] = ["groupId": groupId]
            if let t = traits  { args["traits"] = t }
            if let o = options { args["options"] = o }
            try sutClient.post("/command", body: ["cmd": "group", "args": args])

        case let .alias(newId, previousId, options):
            var args: [String: Any] = ["newId": newId]
            if let p = previousId { args["previousId"] = p }
            if let o = options    { args["options"] = o }
            try sutClient.post("/command", body: ["cmd": "alias", "args": args])

        case let .startSession(id):
            var args: [String: Any] = [:]
            if let id { args["sessionId"] = id }
            try sutClient.post("/command", body: ["cmd": "startSession", "args": args])

        case .endSession:
            try sutClient.post("/command", body: ["cmd": "endSession"])

        case .background:
            lifecycle.background()

        case .foreground:
            lifecycle.foreground()

        case .kill:
            lifecycle.terminate()

        case .coldStart:
            lifecycle.coldStart()
            try rediscoverPort()

        case .networkOffline:
            mockServer.simulateOffline()

        case .networkOnline:
            mockServer.simulateOnline()

        case let .deepLink(url):
            try sutClient.post("/command", body: ["cmd": "openURL", "args": ["url": url]])

        case let .localeChange(locale):
            lifecycle.coldStart(locale: locale)

        case let .crash(kind):
            let cmd = kind == .native ? "nativeCrash" : "crash"
            try? sutClient.post("/command", body: ["cmd": cmd])

        case let .waitForBatch(timeout):
            guard mockServer.waitForBatch(timeout: timeout) != nil else {
                throw ScenarioError.assertionFailed("No batch arrived within \(timeout)s")
            }

        case let .waitForEvent(name, timeout, predicate):
            let batch = mockServer.waitForBatch(timeout: timeout) { batch in
                let events = batch["batch"] as? [[String: Any]] ?? []
                return events.contains {
                    $0["event"] as? String == name && (predicate?($0) ?? true)
                }
            }
            guard batch != nil else {
                throw ScenarioError.assertionFailed("Event '\(name)' not found within \(timeout)s")
            }

        case let .assertNoEvent(name, window):
            let checkpoint = mockServer.currentBatchIndex()
            Thread.sleep(forTimeInterval: window)
            let found = mockServer.waitForBatch(timeout: 0, after: checkpoint) { batch in
                let events = batch["batch"] as? [[String: Any]] ?? []
                return events.contains { $0["event"] as? String == name }
            }
            if found != nil {
                throw ScenarioError.assertionFailed("Event '\(name)' arrived during the \(window)s window but should not have")
            }

        case let .assertState(key, expected):
            let response = try sutClient.get("/state/\(key)")
            guard isEqual(response["value"], expected) else {
                throw ScenarioError.assertionFailed(
                    "State '\(key)': expected \(expected), got \(String(describing: response["value"]))")
            }

        case .snapshotState:
            savedStateBlob = try sutClient.get("/state/export")

        case let .importState(blob):
            try sutClient.post("/state/import", body: blob)
        }
    }
}

// MARK: - Port Discovery

extension Interpreter {

    func rediscoverPort() throws {
        let portElement = app.otherElements.matching(identifier: "sut_port").firstMatch
        guard portElement.waitForExistence(timeout: 5),
              let newPort = UInt16(portElement.label)
        else {
            throw ScenarioError.assertionFailed("SUT did not publish its port after relaunch within 5s")
        }
        sutClient = SUTClient(baseURL: "http://127.0.0.1:\(newPort)")
    }
}

// MARK: - Helpers

extension Interpreter {

    private func isEqual(_ a: Any?, _ b: Any) -> Bool {
        guard let a else { return false }
        guard let lhs = a as? NSObject, let rhs = b as? NSObject else {
            return String(describing: a) == String(describing: b)
        }
        return lhs.isEqual(rhs)
    }
}

// MARK: - Errors

enum ScenarioError: Error {
    case assertionFailed(String)
    case timeout(String)
}
