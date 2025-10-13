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
                }, title: "Track")
                
                ShareExtensionButton(action: {
                    onButtonTapped(nil, .flush)
                }, title: "Flush")
            }
            
            ShareExtensionButton(action: {
                onButtonTapped(nil, .shutdown)
            }, title: "Shutdown")
            
            ShareExtensionButton(action: {
                onButtonTapped(nil, .cancel)
            }, title: "Cancel", isCancel: true)
            
            Spacer()
            
            Text("This is not a proper share extension; it’s a demo app built only to showcase how RudderStackAnalytics works inside an extension.")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray.opacity(0.2))
                .foregroundColor(.black.opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1))
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - ShareExtensionButton
struct ShareExtensionButton: View {
    var action: @MainActor () -> Void
    var title: String
    var isCancel: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
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
