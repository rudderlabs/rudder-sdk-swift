//
//  DebugBundle.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import XCTest

extension ScenarioTestCase {

    override func tearDown() {
        if testRun?.failureCount ?? 0 > 0 {
            collectDebugBundle()
        }
        super.tearDown()
    }
}

// MARK: - Bundle Collection

extension ScenarioTestCase {

    private func collectDebugBundle() {
        let bundleDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("scenario-debug-\(name)")
        try? FileManager.default.createDirectory(at: bundleDir,
                                                 withIntermediateDirectories: true)

        attachScreenshot()
        collectMockServerLog(into: bundleDir)
        collectStepLog(into: bundleDir)
        attachDebugFiles(from: bundleDir)
    }

    private func attachScreenshot() {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment  = XCTAttachment(screenshot: screenshot)
        attachment.name = "failure-screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func collectMockServerLog(into dir: URL) {
        guard let mockServer else { return }
        try? mockServer.requestLog().write(
            to: dir.appendingPathComponent("mock-server.json"),
            atomically: true, encoding: .utf8
        )
    }

    private func collectStepLog(into dir: URL) {
        guard let interpreter else { return }
        let log = interpreter.executedSteps.map { "\($0)" }.joined(separator: "\n")
        try? log.write(
            to: dir.appendingPathComponent("steps.txt"),
            atomically: true, encoding: .utf8
        )
    }

    private func attachDebugFiles(from dir: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return }
        for file in files {
            let attachment = XCTAttachment(contentsOfFile: file)
            attachment.name = file.lastPathComponent
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
