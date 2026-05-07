//
//  RudderSUTApp.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import SwiftUI

/**
 * RudderSUTApp is the main entry point of the test application.
 *
 * It initializes the core communication infrastructure during the application launch phase.
 * The AppDelegate handles the sequential setup of the CommandServer and CommandDispatcher,
 * ensuring that the internal test server is active and the UI is synchronized with the
 * server's state (e.g., the active port) via the environment.
 */
@main
struct RudderSUTApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ServerState.shared)
        }
    }
}

/**
 * AppDelegate manages the application lifecycle events.
 * Specifically, it handles the initialization and startup of the command server
 * and synchronizes the shared server state for the UI.
 */
class AppDelegate: NSObject, UIApplicationDelegate {
    private var commandServer: CommandServer!

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        commandServer = CommandServer()
        CommandDispatcher.shared.configure(sseStream: commandServer.sseStream)
        commandServer.start()
        ServerState.shared.port = commandServer.port
        return true
    }
}
