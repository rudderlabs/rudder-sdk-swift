//
//  DynamicUserAgentPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 04/09/25.
//

import Foundation
import RudderStackAnalytics

#if canImport(WebKit)
import WebKit
#endif

// MARK: - DynamicUserAgentPlugin
/**
 A plugin that dynamically adds User Agent information to the event payload.

 ## Usage:
 ```swift
 // Create and add the plugin
 let userAgentPlugin = DynamicUserAgentPlugin()
 analytics.add(plugin: userAgentPlugin)
 ```
 */
final class DynamicUserAgentPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    var userAgent: String?
    
    init() {
        // Read user agent on initialization on main thread
        Task { @MainActor [weak self] in
            guard let self else {
                LoggerAnalytics.debug(log: "Failed to read user agent")
                return
            }
            self.userAgent = await self.readUserAgent()
        }
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard let userAgent else { return event }
        
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        contextDict["userAgent"] = userAgent
        updatedEvent.context = contextDict.codableWrapped
        
        return updatedEvent
    }
}

// MARK: - UserAgent
extension DynamicUserAgentPlugin {
    
    /**
     Reads the User Agent string using a WKWebView instance.
     
     - Returns: The User Agent string from WebKit's `navigator.userAgent` if available, otherwise nil.
     - Note: This method must be called on the main thread as `WKWebView` requires it.
     */
    
    @MainActor
    func readUserAgent() async -> String? {
#if canImport(WebKit)
        do {
            let webView = WKWebView(frame: .zero)
            guard let ua = try await webView.evaluateJavaScript("navigator.userAgent") as? String,
                  !ua.isEmpty else {  return nil }
            LoggerAnalytics.debug(log: "User Agent: \(ua)")
            return ua
            
        } catch {
            LoggerAnalytics.error(log: "Failed to read user agent", error: error)
            return nil
        }
#else
        return nil
#endif
    }
}
