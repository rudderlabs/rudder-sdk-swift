//
//  SimctlHelper.swift
//  RudderUITests
//
//  Created by Satheesh Kannan on 07/05/26.
//

import Foundation

class SimctlHelper {

    // MARK: - Properties

    private let deviceUDID = "booted"
}

// MARK: - simctl Commands

extension SimctlHelper {

    func openURL(_ url: String) throws {
        try run(["openurl", deviceUDID, url])
    }

    func setLocale(_ identifier: String) throws {
        try run(["spawn", deviceUDID, "defaults", "write", "-g",
                 "AppleLanguages", "(\(identifier))"])
        try run(["spawn", deviceUDID, "defaults", "write", "-g",
                 "AppleLocale", identifier])
    }
}

// MARK: - Internal

extension SimctlHelper {

    @discardableResult
    private func run(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments     = ["simctl"] + args

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? ""
    }
}
