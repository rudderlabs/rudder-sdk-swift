//
//  ContentView.swift
//  RudderSUT
//
//  Created by Satheesh Kannan on 07/05/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serverState: ServerState

    var body: some View {
        Color.clear
            .accessibilityElement()
            .accessibilityIdentifier("sut_port")
            .accessibilityLabel(serverState.port.map { "\($0)" } ?? "")
    }
}
