//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI
import RudderStackAnalytics

struct ContentView: View {
    
    var body: some View {
        VStack {
            HStack {
                CustomButton(title: "Identify") {
                    let options = RudderOption(integrations: ["Amplitude": false], customContext: ["identify_key1": "identify_value1"], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                    
                    AnalyticsManager.shared.identify(userId: "12345", traits: ["IdentifyTraits_key1": "IdentifyTraits_value1"], options: options)
                }
                
                CustomButton(title: "Alias") {
                    let options = RudderOption(integrations: ["Amplitude": false], customContext: ["identify_key1": "identify_value1"], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                    
                    AnalyticsManager.shared.alias(newId: "123_alias_123", options: options)
                }
            }
            
            HStack {
                let sampleURL = "https://www.rsa-test.com/"
                CustomButton(title: "Track") {
                    let option = RudderOption(integrations: ["Amplitude": true, "CleverTap": false], customContext: ["Key_1": ["Key1": "Value1"], "Key_2": ["value1", "value2"], "Key_3": "Value3", "Key_4": 1234, "Key_5": 5678.9, "Key_6": true, "Key_7": URL(string: sampleURL) ?? sampleURL], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                    
                    AnalyticsManager.shared.track(name: "Track at \(Date())", properties: ["key": "value"], options: option)
                }
                
                CustomButton(title: "Multiple Track") {
                    let option = RudderOption(integrations: ["Amplitude": true, "CleverTap": false], customContext: ["Key_1": ["Key123": "Value123"]], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                    for i in 1...50 {
                        AnalyticsManager.shared.track(name: "Track: \(i)", options: option)
                    }
                }
            }
            
            HStack {
                CustomButton(title: "Screen") {
                    let option = RudderOption(integrations: ["Facebook": false], customContext: ["Key_1": ["Key1": "Value1"]], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                    AnalyticsManager.shared.screen(name: "Analytics Screen", properties: ["key": "value"], options: option)
                }
                
                CustomButton(title: "Group") {
                    let option = RudderOption(integrations: ["Firebase": false, "Twitter": ["isEnabled": true, "consumerKey": "consumerSecret"]], customContext: ["Key_1": ["Key1": "Value1"]], externalIds: [ExternalId(type: "idCardNumber", id: "12791"), ExternalId(type: "official_idCardNumber", id: "AB123CD")])
                    AnalyticsManager.shared.group(id: "group_id", traits: ["key": "value"], options: option)
                }
                
                CustomButton(title: "Flush") {
                    AnalyticsManager.shared.flush()
                }
            }
            
            HStack {
                CustomButton(title: "Read AnonymousId") {
                    if let anonymousId = AnalyticsManager.shared.anonymousId {
                        LoggerAnalytics.debug("Current Anonymous Id: \(anonymousId)")
                    } else {
                        LoggerAnalytics.debug("Current Anonymous Id: nil")
                    }
                }
                
                CustomButton(title: "Read UserId") {
                    if let userId = AnalyticsManager.shared.userId {
                        LoggerAnalytics.debug("Current User Id: \(userId)")
                    } else {
                        LoggerAnalytics.debug("Current User Id: nil")
                    }
                }
            }
            
            HStack {
                CustomButton(title: "Reset") {
                    AnalyticsManager.shared.reset()
                }
            }
            
            HStack {
                CustomButton(title: "Start Session") {
                    AnalyticsManager.shared.startSession()
                }
                
                CustomButton(title: "Start Session with SessionId") {
                    AnalyticsManager.shared.startSession(sessionId: 12312312345)
                }
            }
            
            HStack {
                CustomButton(title: "Read SessionId") {
                    if let sessionId = AnalyticsManager.shared.sessionId {
                        LoggerAnalytics.debug("Current Session Id: \(String(sessionId))")
                    } else {
                        LoggerAnalytics.debug("No active session found.")
                    }
                }
                
                CustomButton(title: "End Session") {
                    AnalyticsManager.shared.endSession()
                }
            }
            
            HStack {
                CustomButton(title: "Shutdown") {
                    AnalyticsManager.shared.shutdown()
                }
                
                CustomButton(title: "Initialize SDK") {
                    AnalyticsManager.shared.initializeAnalyticsSDK()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

struct CustomButton: View {
    
    let title: String
    let action: () -> Void
    
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(.blue)
        }
        .padding(5)
    }
}
