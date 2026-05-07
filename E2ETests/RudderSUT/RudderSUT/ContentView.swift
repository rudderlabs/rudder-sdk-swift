//
//  ContentView.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import SwiftUI

/**
 * ContentView defines the main user interface for the test app.
 *
 * In this SUT (System Under Test) application, the UI is deliberately minimal and invisible.
 * Its primary role is to expose internal state—specifically the active server port—via
 * accessibility identifiers. This allows the automated test framework to discover
 * how to communicate with the app's internal command server.
 */
struct ContentView: View {
    @EnvironmentObject var serverState: ServerState

    var body: some View {
        // Color.clear can be stripped from the accessibility tree on newer iOS.
        // Text always survives because it has content — its text IS its accessibility label.
        Text(serverState.port.map { String($0) } ?? "")
            .accessibilityIdentifier("sut_port")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(0.001)
    }
}
