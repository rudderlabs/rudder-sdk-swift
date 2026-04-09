//
//  MainViewModel.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 01/04/26.
//

import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    @Published var lastPayload: String = ""
    @Published var isAdvertisingIdEnabled: Bool = false {
        didSet { handleAdvertisingIdToggle() }
    }

    private var advertisingPlugin: AdvertisingIdPlugin?

    init() {
        AnalyticsManager.shared.onPayloadCaptured = { [weak self] json in
            Task { @MainActor [weak self] in
                self?.lastPayload = json
            }
        }
    }

    // MARK: - Public API
    func track()    { AnalyticsManager.shared.track(name: "Track Example") }
    func screen()   { AnalyticsManager.shared.screen(name: "Main Screen") }
    func group()    { AnalyticsManager.shared.group(id: "Group ID") }
    func identify() { AnalyticsManager.shared.identify(userId: "User123") }
    func alias()    { AnalyticsManager.shared.alias(newId: "NewAlias", previousId: "OldAlias") }
    func flush()    { AnalyticsManager.shared.flush(); lastPayload = "" }

    // MARK: - Features
    func startSession()             { AnalyticsManager.shared.startSession() }
    func startSessionWithCustomId() { AnalyticsManager.shared.startSession(sessionId: 1000000001) }
    func endSession()               { AnalyticsManager.shared.endSession() }
    func reset()                    { AnalyticsManager.shared.reset() }
    func shutdown()                 { AnalyticsManager.shared.shutdown() }

    // MARK: - Advertising ID
    private func handleAdvertisingIdToggle() {
        if isAdvertisingIdEnabled {
            let plugin = AdvertisingIdPlugin()
            advertisingPlugin = plugin
            AnalyticsManager.shared.addPlugin(plugin)
        } else {
            guard let advertisingPlugin else { return }
            AnalyticsManager.shared.removePlugin(advertisingPlugin)
            self.advertisingPlugin = nil
        }
    }
}
