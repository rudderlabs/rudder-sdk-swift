//
//  AppUtils.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 01/04/26.
//

import SwiftUI

// MARK: - ActionButton

struct ActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color.rudderBlue)
        .cornerRadius(12)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ButtonGrid

struct ButtonGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            content()
        }
    }
}

// MARK: - AdvertisingIdToggleRow

struct AdvertisingIdToggleRow: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Text("Enable Advertising ID")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color.rudderBlue)
        }
    }
}

// MARK: - PayloadView

struct PayloadView: View {
    @Binding var payload: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Payload Generated")
            TextEditor(text: .constant(payload))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minHeight: 160)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
                .disabled(true)
        }
    }
}

// MARK: - Encoder

extension Encodable {
    var jsonString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

// MARK: - View

extension View {
    func whiteNavigationBar() -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
