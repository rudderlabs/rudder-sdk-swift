//
//  ShareExtensionView.swift
//  ShareExtension
//
//  Created by Satheesh Kannan on 07/10/25.
//

import SwiftUI

// MARK: - ShareExtensionView
struct ShareExtensionView: View {
    @State var text: String
    var onButtonTapped: (String?, ShareButtonActionType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics Actions")
                .font(.title3)
                .bold()
            
            TextEditor(text: $text)
                .font(.body)
                .padding(8)
                .frame(height: 120) // 👈 Limit height
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            
            HStack {
                ShareExtensionButton(action: {
                    onButtonTapped(text, .track)
                }, tite: "Track")
                
                ShareExtensionButton(action: {
                    onButtonTapped(nil, .flush)
                }, tite: "Flush")
            }
            
            ShareExtensionButton(action: {
                onButtonTapped(nil, .shutdown)
            }, tite: "Shutdown")
            
            ShareExtensionButton(action: {
                onButtonTapped(nil, .cancel)
            }, tite: "Cancel", isCancel: true)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - ShareExtensionButton
struct ShareExtensionButton: View {
    var action: @MainActor () -> Void
    var tite: String
    var isCancel: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(tite)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCancel ? .gray.opacity(0.2) : .blue)
                .foregroundColor(isCancel ? .black.opacity(0.5) : .white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCancel ? Color.gray.opacity(0.4) : .clear, lineWidth: 1))
        }
    }
}

// MARK: - ShareButtonActionType
enum ShareButtonActionType {
    case track
    case flush
    case shutdown
    case cancel
}

#Preview {
    ShareExtensionView(text: "Hit it.!!") {_,_  in }
}
