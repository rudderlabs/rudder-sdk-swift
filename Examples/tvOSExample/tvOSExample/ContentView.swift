//
//  ContentView.swift
//  tvOSExample
//
//  Created by Satheesh Kannan on 04/06/25.
//

import SwiftUI
import RudderStackAnalytics

struct ContentView: View {
    @State private var displayUserId: String = "None"
    @State private var displayAnonymousId: String = "None"
    @State private var displaySessionId: String = "None"
    @State private var displayTraits: String = "None"
    @FocusState private var focusedButton: ButtonIdentifier?

    enum ButtonIdentifier: Hashable {
        case refresh
        case track, screen, group, identify, alias, reset, flush
        case startSession, endSession, sessionWithId
        case deepLink, shutdown
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 50) {
                VStack {
                    VStack(alignment: .leading, spacing: 15) {
                        section("Current User Info:")
                        
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
                    .frame(maxWidth: geometry.size.width * 0.4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    
                    CustomButton(title: "Refresh Info") {
                        updateUserInfo()
                        updateSessionInfo()
                    }
                    .focused($focusedButton, equals: .refresh)
                    
                    Spacer()
                }
                .frame(minWidth: geometry.size.width * 0.5, minHeight: geometry.size.height)
                .focusSection()
                
                // MARK: - Event Actions Panel
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        section("Event Tracking:")
                        CustomButton(title: "Track Event") {
                            AnalyticsManager.shared.track(
                                name: "Track at \(Date())",
                                properties: ["key": "value"]
                            )
                        }
                        .focused($focusedButton, equals: .track)
                        
                        CustomButton(title: "Screen Event") {
                            AnalyticsManager.shared.screen(
                                name: "Main Screen",
                                category: "Navigation",
                                properties: ["screen_type": "main"]
                            )
                        }
                        .focused($focusedButton, equals: .screen)
                        
                        CustomButton(title: "Group Event") {
                            let groupTraits: Traits = [
                                "name": "Acme Corp", "plan": "enterprise", "employees": 500
                            ]
                            AnalyticsManager.shared.group(id: "group_456", traits: groupTraits)
                        }
                        .focused($focusedButton, equals: .group)
                        
                        CustomButton(title: "Identify Event") {
                            let traits: Traits = [
                                "name": "John Doe", "email": "john.doe@example.com",
                                "age": 30, "premium": true
                            ]
                            let option = RudderOption(
                                integrations: ["Amplitude": true, "CleverTap": false],
                                customContext: [
                                    "key1": ["Key1": "Value1"],
                                    "key2": ["value1", "value2"],
                                    "key3": "Value3",
                                    "key4": 1234,
                                    "key5": 5678.9,
                                    "key6": true
                                ],
                                externalIds: [ExternalId(type: "idCardNumber", id: "12791")]
                            )
                            AnalyticsManager.shared.identify(userId: "user_123", traits: traits, options: option)
                            updateUserInfo()
                        }
                        .focused($focusedButton, equals: .identify)
                        
                        CustomButton(title: "Alias Event") {
                            AnalyticsManager.shared.alias(
                                newId: "user_new_123",
                                previousId: AnalyticsManager.shared.userId
                            )
                            updateUserInfo()
                        }
                        .focused($focusedButton, equals: .alias)
                        
                        Divider()
                        
                        section("Additional APIs:")
                        CustomButton(title: "Reset User") {
                            AnalyticsManager.shared.reset()
                            updateUserInfo()
                            updateSessionInfo()
                        }
                        .focused($focusedButton, equals: .reset)
                        
                        CustomButton(title: "Flush Events") {
                            AnalyticsManager.shared.flush()
                        }
                        .focused($focusedButton, equals: .flush)
                        
                        Divider()
                        
                        section("Session Management:")
                        CustomButton(title: "Start Session") {
                            AnalyticsManager.shared.startSession()
                            updateSessionInfo()
                        }
                        .focused($focusedButton, equals: .startSession)
                        
                        CustomButton(title: "Start Session with ID") {
                            let sessionId = UInt64(Date().timeIntervalSince1970 * 1000)
                            AnalyticsManager.shared.startSession(sessionId: sessionId)
                            updateSessionInfo()
                        }
                        .focused($focusedButton, equals: .sessionWithId)
                        
                        CustomButton(title: "End Session") {
                            AnalyticsManager.shared.endSession()
                            updateSessionInfo()
                        }
                        .focused($focusedButton, equals: .endSession)
                        
                        Divider()
                        
                        section("Deep Link Tracking:")
                        CustomButton(title: "Track Deep Link") {
                            if let url = URL(string: "https://example.com/deeplink?utm_source=email&utm_campaign=welcome") {
                                AnalyticsManager.shared.openURL(url, options: ["source": "test_button"])
                            }
                        }
                        .focused($focusedButton, equals: .deepLink)
                        
                        Divider()
                        
                        section("System Management:")
                        CustomButton(title: "Shutdown Analytics") {
                            AnalyticsManager.shared.shutdown()
                            updateUserInfo()
                            updateSessionInfo()
                        }
                        .focused($focusedButton, equals: .shutdown)
                        
                        Spacer(minLength: 50.0)
                    }
                }
                .focusSection()
                .padding()
            }
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
    
    @ViewBuilder
    func section(_ title: String) -> some View {
        Text(title)
            .font(.headline.italic())
            .underline()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}

// MARK: - CustomButton
struct CustomButton: View {
    let title: String
    let action: () -> Void
    var fixedWidth: CGFloat = 450  // default width

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(width: fixedWidth, height: 80) // fixed width and height
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
        .padding(.vertical, 5)
        .padding(.horizontal, 80)
    }
}
