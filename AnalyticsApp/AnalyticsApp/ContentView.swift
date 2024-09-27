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
            Text("Track Event")
                .font(.title)
                .padding()
                .foregroundStyle(.white)
                .background(.blue)
                .onTapGesture {
                    AnalyticsManager.shared.analytics?.track(name: "Track at \(Date())")
                }
                .padding()
            
            Text("Track Multiple Event")
                .font(.title)
                .padding()
                .foregroundStyle(.white)
                .background(.blue)
                .onTapGesture {
                    for i in 1...50 {
                        AnalyticsManager.shared.analytics?.track(name: "Track: \(i)")
                    }
                }
                .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
