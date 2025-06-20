//
//  ContentView.swift
//  macOSExample
//
//  Created by Satheesh Kannan on 30/05/25.
//

import SwiftUI
import RudderStackAnalytics

// MARK: - ContentView
struct ContentView: View {
    @State private var displayUserId: String = "None"
    @State private var displayAnonymousId: String = "None"
    @State private var displaySessionId: String = "None"
    @State private var displayTraits: String = "None"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
                // User Info Display
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current User Info")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("User ID: \(displayUserId)")
                        .font(.caption)
                    Text("Anonymous ID: \(displayAnonymousId)")
                        .font(.caption)
                    Text("Session ID: \(displaySessionId)")
                        .font(.caption)
                    Text("Traits: \(displayTraits)")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Refresh Button
                CustomButton(title: "Refresh Info") {
                    updateUserInfo()
                    updateSessionInfo()
                }
                
                Divider()
                
                // Event Tracking Section
                Text("Event Tracking")
                    .font(.headline)
                
                CustomButton(title: "Track Event") {
                    AnalyticsManager.shared.track(
                        name: "Track at \(Date())",
                        properties: ["key": "value"]
                    )
                }
                
                CustomButton(title: "Screen Event") {
                    AnalyticsManager.shared.screen(
                        name: "Main Screen",
                        category: "Navigation",
                        properties: ["screen_type": "main"]
                    )
                }
                
                CustomButton(title: "Group Event") {
                    let groupTraits: RudderTraits = [
                        "name": "Acme Corp",
                        "plan": "enterprise",
                        "employees": 500
                    ]
                    AnalyticsManager.shared.group(id: "group_456", traits: groupTraits)
                }
                
                CustomButton(title: "Identify Event") {
                    let option = RudderOption(
                        integrations: [
                            "Amplitude": true,
                            "CleverTap": false
                        ],
                        customContext: [
                            "key1": ["Key1": "Value1"],
                            "key2": ["value1", "value2"],
                            "key3": "Value3",
                            "key4": 1234,
                            "key5": 5678.9,
                            "key6": true
                        ],
                        externalIds: [
                            ExternalId(type: "idCardNumber", id: "12791")
                        ]
                    )
                    
                    let traits: RudderTraits = [
                        "name": "John Doe",
                        "email": "john.doe@example.com",
                        "age": 30,
                        "premium": true
                    ]
                    AnalyticsManager.shared.identify(userId: "user_123", traits: traits, options: option)
                    updateUserInfo()
                }
                
                CustomButton(title: "Alias Event") {
                    AnalyticsManager.shared.alias(
                        newId: "user_new_123",
                        previousId: AnalyticsManager.shared.userId
                    )
                    updateUserInfo()
                }
                
                Divider()
                
                // Additional API's
                Text("Additional APIs")
                    .font(.headline)
                
                CustomButton(title: "Reset User") {
                    AnalyticsManager.shared.reset()
                    updateUserInfo()
                    updateSessionInfo()
                }
                
                CustomButton(title: "Flush Events") {
                    AnalyticsManager.shared.flush()
                }
                
                Divider()
                
                // Session Management Section
                Text("Session Management")
                    .font(.headline)
                
                CustomButton(title: "Start Session") {
                    AnalyticsManager.shared.startSession()
                    updateSessionInfo()
                }
                
                CustomButton(title: "Start Session with ID") {
                    let sessionId: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)
                    AnalyticsManager.shared.startSession(sessionId: sessionId)
                    updateSessionInfo()
                }
                
                CustomButton(title: "End Session") {
                    AnalyticsManager.shared.endSession()
                    updateSessionInfo()
                }
                
                Divider()
                
                // Deep Link Tracking Section
                Text("Deep Link Tracking")
                    .font(.headline)
                
                CustomButton(title: "Track Deep Link") {
                    if let url = URL(string: "https://example.com/deeplink?utm_source=email&utm_campaign=welcome") {
                        AnalyticsManager.shared.openURL(url, options: ["source": "test_button"])
                    }
                }
                
                Divider()
                
                // System Management Section
                Text("System Management")
                    .font(.headline)
                
                CustomButton(title: "Shutdown Analytics") {
                    AnalyticsManager.shared.shutdown()
                    updateUserInfo()
                    updateSessionInfo()
                }
            }
            .padding()
        }
        .onAppear {
            updateUserInfo()
            updateSessionInfo()
        }
    }
    
    private func updateUserInfo() {
        displayUserId = AnalyticsManager.shared.userId ?? "None"
        displayAnonymousId = AnalyticsManager.shared.anonymousId ?? "None"
        displayTraits = AnalyticsManager.shared.traits?.description ?? "None"
    }
    
    private func updateSessionInfo() {
        displaySessionId = AnalyticsManager.shared.sessionId?.description ?? "None"
    }
}

#Preview {
    ContentView()
}

// MARK: - CustomButton
struct CustomButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
                .foregroundColor(Color.accentColor)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(6)
    }
}
