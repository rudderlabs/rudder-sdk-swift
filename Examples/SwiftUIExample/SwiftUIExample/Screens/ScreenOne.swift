//
//  ScreenOne.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 01/04/26.
//

import SwiftUI

struct ScreenOne: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen One")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 16)

            NavigationLink(destination: ScreenTwo(viewModel: viewModel)) {
                Text("Navigate to Screen Two")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rudderBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)

            PayloadView(payload: $viewModel.lastPayload)
                .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.top, 16)
        .background(Color.white)
        .navigationTitle("Rudderstack Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .whiteNavigationBar()
        .onAppear {
            AnalyticsManager.shared.screen(name: "Screen One")
        }
    }
}
