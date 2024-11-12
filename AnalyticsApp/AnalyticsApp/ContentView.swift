//
//  ContentView.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI
import Analytics

struct ContentView: View {
    
    var body: some View {
        VStack {
            HStack {
                CustomButton(title: "Track") {
                    let option = RudderOptions()
                    .addIntegration("SDK", isEnabled: true)
                    .addIntegration("Segment", isEnabled: false)
                    .addCustomContext(["Key123": "Value123"], key: "SK123")
                    .addCustomContext(["Key1234": "Value1234"], key: "SK1234")
                    
                    AnalyticsManager.shared.analytics?.track(name: "Track at \(Date())", properties: ["key": "value"], options: option)
                }
                
                CustomButton(title: "Multiple Track") {
                    let option = RudderOptions()
                    .addIntegration("SDK", isEnabled: true)
                    .addIntegration("Segment", isEnabled: false)
                    .addCustomContext(["Key123": "Value123"], key: "SK123")
                    
                    for i in 1...50 {
                        AnalyticsManager.shared.analytics?.track(name: "Track: \(i)", options: option)
                    }
                }
            }
            
            HStack {
                CustomButton(title: "Screen") {
                    let option = RudderOptions()
                        .addCustomContext(["Key1": "Value1"], key: "SK")
                        .addIntegration("Segment", isEnabled: false)
                    AnalyticsManager.shared.analytics?.screen(name: "Analytics Screen", properties: ["key": "value"], options: option)
                }
                
                CustomButton(title: "Group") {
                    let option = RudderOptions()
                        .addCustomContext(["Key1": "Value1"], key: "SK")
                        .addIntegration("MySDK", isEnabled: false)
                    AnalyticsManager.shared.analytics?.group(id: "group_id", traits: ["key": "value"], options: option)
                }
            }
            
            HStack {
                CustomButton(title: "Flush") {
                    AnalyticsManager.shared.analytics?.flush()
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
        Text(title)
            .font(.title3)
            .padding()
            .foregroundStyle(.white)
            .background(.blue)
            .onTapGesture { action() }
            .padding()
    }
}
