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
                Text("Track")
                    .font(.title3)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.blue)
                    .onTapGesture {
                        AnalyticsManager.shared.analytics?.track(name: "Track at \(Date())")
                    }
                    .padding()
                
                Text("Multiple Track")
                    .font(.title3)
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
            
            HStack {
                Text("Flush")
                    .font(.title3)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.blue)
                    .onTapGesture {
                        AnalyticsManager.shared.analytics?.flush()
                    }
                    .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
