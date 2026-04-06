//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Public API Section
                    SectionHeader(title: "Public API")
                    ButtonGrid {
                        ActionButton(title: "Track")    { viewModel.track() }
                        ActionButton(title: "Screen")   { viewModel.screen() }
                        ActionButton(title: "Group")    { viewModel.group() }
                        ActionButton(title: "Identify") { viewModel.identify() }
                        ActionButton(title: "Alias")    { viewModel.alias() }
                        ActionButton(title: "Flush")    { viewModel.flush() }
                    }
                    
                    // MARK: - Features Section
                    SectionHeader(title: "Features")

                    ButtonGrid {
                        ActionButton(title: "Start Session")    { viewModel.startSession() }
                        ActionButton(title: "Start Session with custom id") { viewModel.startSessionWithCustomId() }
                        ActionButton(title: "End Session")  { viewModel.endSession() }
                        ActionButton(title: "Reset")    { viewModel.reset() }
                    }
                    ActionButton(title: "Shutdown") { viewModel.shutdown() }
                    
                    // MARK: - Advertising ID Toggle
                    AdvertisingIdToggleRow(isEnabled: $viewModel.isAdvertisingIdEnabled)
                    
                    // MARK: - Payload Display
                    PayloadView(payload: $viewModel.lastPayload)
                }
                .padding(16)
            }
            .background(Color.white)
            .navigationTitle("Rudderstack Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .whiteNavigationBar()
        }
    }
}

#Preview {
    ContentView()
}
