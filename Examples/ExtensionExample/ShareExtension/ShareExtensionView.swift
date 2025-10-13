//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Created by Satheesh Kannan on 07/10/25.
//

import SwiftUI

struct ShareExtensionView: View {
    @State var text: String
    var onSend: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make an Event")
                .font(.title3)
                .bold()
            
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .frame(height: 120) // 👈 Limit height
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            Button(action: {
                onSend(text)
            }) {
                Text("Send")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    ShareExtensionView(text: "Hit it.!!") {_ in }
}
