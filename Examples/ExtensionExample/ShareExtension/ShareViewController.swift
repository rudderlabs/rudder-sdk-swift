//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Satheesh Kannan on 07/10/25.
//

import UIKit
import Social
import SwiftUI
import RudderStackAnalytics

class ShareViewController: UIViewController {
    
    var analytics: Analytics?
    
    override func loadView() {
        super.loadView()
        self.initializeAnalyticsSDK()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let screen = view.window?.windowScene?.screen {
            preferredContentSize = CGSize(width: screen.bounds.width, height: 260)
        }
        // Extract shared text
        handleIncomingText()
    }
    
    private func handleIncomingText() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else { return }
        
        for provider in attachments where provider.hasItemConformingToTypeIdentifier("public.text") {
            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to load text: \(error.localizedDescription)")
                    return
                }
                
                var sharedText: String?
                
                if let text = item as? String {
                    sharedText = text
                } else if let url = item as? URL {
                    sharedText = url.absoluteString
                }
                
                guard let text = sharedText else { return }
                
                DispatchQueue.main.async {
                    self.showSwiftUIView(with: text)
                }
            }
        }
    }
    
    private func showSwiftUIView(with text: String) {
        let contentView = UIHostingController(rootView: ShareExtensionView(text: text) {
            self.handleSend(text: $0)
        })
        
        addChild(contentView)
        view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        contentView.didMove(toParent: self)
    }
    
    private func handleSend(text: String) {
        // ✅ Handle your send action here
        // e.g., save to shared UserDefaults, write to a shared file, or trigger an API
        
        self.analytics?.track(name: text)
        
        // Complete the share
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.analytics?.flush()
            // Wait briefly before ending the extension
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.analytics?.shutdown()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.analytics = nil
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)}
            }
        }
    }
}

extension ShareViewController {
    func initializeAnalyticsSDK() {
        // Set the log level for analytics
        LoggerAnalytics.logLevel = .verbose

        // Initialize the RudderStack Analytics SDK
        let config = Configuration(writeKey: "<WRITE_KEY>", dataPlaneUrl: "<DATA_PLANE_URL>")
        self.analytics = Analytics(configuration: config)
    }
}
