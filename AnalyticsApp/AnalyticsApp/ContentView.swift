//
//  ContentView.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 14/08/24.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack {
            HStack {
                CustomButton(title: "Track") {
                    AnalyticsManager.shared.analytics?.track(name: "Track at \(Date())", properties: ["key": "value"], options: ["option": "value"])
                }
                
                CustomButton(title: "Multiple Track") {
                    for i in 1...50 {
                        AnalyticsManager.shared.analytics?.track(name: "Track: \(i)")
                    }
                }
            }
            
            HStack {
                CustomButton(title: "Screen") {
                    AnalyticsManager.shared.analytics?.screen(name: "Analytics Screen", properties: ["key": "value"], options: ["option": "value"])
                }
                
                CustomButton(title: "Group") {
                    AnalyticsManager.shared.analytics?.group(id: "group_id", traits: ["key": "value"], options: ["option": "value"])
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
