//
//  ContentView.swift
//  AnalyticsAppWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
//

import SwiftUI
import Analytics

// MARK: - ContentView
struct ContentView: View {
    @State private var displayUserId: String = "None"
    @State private var displayAnonymousId: String = "None" 
    @State private var displaySessionId: String = "None"
    @State private var displayTraits: String = "None"
    
    var body: some View {
        NavigationView {
            List {
                    // User Info Display Section
                Section("Current User Info") {
                    VStack(alignment: .leading, spacing: 2) {
                        InfoRow(label: "User ID", value: displayUserId)
                        InfoRow(label: "Anonymous ID", value: displayAnonymousId)
                        InfoRow(label: "Session ID", value: displaySessionId)
                        InfoRow(label: "Traits", value: displayTraits)
                    }
                    .padding(.vertical, 4)
                    
                    WatchButton(title: "Refresh Info") {
                        updateUserInfo()
                        updateSessionInfo()
                    }
                }
                
                    // Event Tracking Section
                Section("Event Tracking") {
                    WatchButton(title: "Track Event") {
                        AnalyticsManager.shared.track(
                            name: "Track at \(Date())",
                            properties: ["key": "value"]
                        )
                    }
                    
                    WatchButton(title: "Screen Event") {
                        AnalyticsManager.shared.screen(
                            name: "Watch Screen",
                            category: "Navigation",
                            properties: ["screen_type": "watch"]
                        )
                    }
                    
                    WatchButton(title: "Group Event") {
                        let groupTraits: RudderTraits = [
                            "name": "Watch Corp",
                            "plan": "basic"
                        ]
                        AnalyticsManager.shared.group(id: "group_watch", traits: groupTraits)
                    }
                    
                    WatchButton(title: "Identify Event") {
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
                            "name": "Watch User",
                            "email": "watch@example.com",
                            "platform": "watchOS"
                        ]
                        AnalyticsManager.shared.identify(userId: "watch_user_123", traits: traits, options: option)
                        updateUserInfo()
                    }
                    
                    WatchButton(title: "Alias Event") {
                        AnalyticsManager.shared.alias(
                            newId: "watch_new_123",
                            previousId: AnalyticsManager.shared.userId
                        )
                        updateUserInfo()
                    }
                }
                
                    // Additional APIs Section
                Section("Additional APIs") {
                    WatchButton(title: "Reset User") {
                        AnalyticsManager.shared.reset()
                        updateUserInfo()
                    }
                    
                    WatchButton(title: "Flush Events") {
                        AnalyticsManager.shared.flush()
                    }
                }
                
                    // Session Management Section
                Section("Session Management") {
                    WatchButton(title: "Start Session") {
                        AnalyticsManager.shared.startSession()
                        updateSessionInfo()
                    }
                    
                    WatchButton(title: "Start Session with ID") {
                        let sessionId: UInt64 = UInt64(Date().timeIntervalSince1970 * 1000)
                        AnalyticsManager.shared.startSession(sessionId: sessionId)
                        updateSessionInfo()
                    }
                    
                    WatchButton(title: "End Session") {
                        AnalyticsManager.shared.endSession()
                        updateSessionInfo()
                    }
                }
                
                    // Deep Link Tracking Section
                Section("Deep Link Tracking") {
                    WatchButton(title: "Track Deep Link") {
                        if let url = URL(string: "https://example.com/deeplink?utm_source=email&utm_campaign=welcome") {
                            AnalyticsManager.shared.openURL(url, options: ["source": "watch_button"])
                        }
                    }
                }
                
                    // System Management Section
                Section("System Management") {
                    WatchButton(title: "Shutdown Analytics") {
                        AnalyticsManager.shared.shutdown()
                        updateUserInfo()
                        updateSessionInfo()
                    }
                }
            }
            .navigationTitle("Analytics")
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

#Preview {
    ContentView()
}

// MARK: - InfoRow
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption2)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - WatchButton
struct WatchButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
