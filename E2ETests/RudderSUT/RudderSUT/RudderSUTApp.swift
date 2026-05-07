//
//  RudderSUTApp.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import SwiftUI

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
