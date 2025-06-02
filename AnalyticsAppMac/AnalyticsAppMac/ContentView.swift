//
//  ContentView.swift
//  AnalyticsAppMac
//
//  Created by Satheesh Kannan on 30/05/25.
//

import SwiftUI
import Analytics

// MARK: - ContentView
struct ContentView: View {
    var body: some View {
        VStack {
            CustomButton(title: "Track Event") {
                let option = RudderOption(integrations: ["Amplitude": true, "CleverTap": false], customContext: ["SK1": ["Key1": "Value1"], "SK2": ["value1", "value2"], "SK3": "Value3", "SK4": 1234, "SK5": 5678.9, "SK6": true], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                
                AnalyticsManager.shared.track(name: "Track at \(Date())", properties: ["key": "value"], options: option)
            }
            
            CustomButton(title: "Multiple Track Event") {
                for i in 1...100 {
                    AnalyticsManager.shared.track(name: "Track Event: \(i)")
                }
            }
            
            CustomButton(title: "Flush") {
                AnalyticsManager.shared.flush()
            }
        }
        .padding()
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
