//
//  ContentView.swift
//  AnalyticsAppWatchKitApp
//
//  Created by Satheesh Kannan on 02/06/25.
//

import SwiftUI
import Analytics

struct ContentView: View {
    var body: some View {
        VStack {
            CustomButton(title: "Track Event") {
                let option = RudderOption(integrations: ["Amplitude": true, "CleverTap": false], customContext: ["SK1": ["Key1": "Value1"], "SK2": ["value1", "value2"], "SK3": "Value3", "SK4": 1234, "SK5": 5678.9, "SK6": true], externalIds: [ExternalId(type: "idCardNumber", id: "12791")])
                
                AnalyticsManager.shared.track(name: "Track at \(Date())", properties: ["key": "value"], options: option)
            }
            
            CustomButton(title: "Multiple Track") {
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
                        .fill(Color.cyan.opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cyan, lineWidth: 1)
                )
                .foregroundColor(Color.white.opacity(0.9))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(6)
    }
}
