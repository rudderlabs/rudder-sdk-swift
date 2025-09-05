//
//  UserAgentPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 04/09/25.
//

import Foundation
import RudderStackAnalytics

#if canImport(WebKit)
import WebKit
#endif

// MARK: - UserAgentPlugin
/**
 A plugin that adds User Agent information to the event payload.
 
 ## Usage:
 ```swift
 // Create and add the plugin
 let userAgentPlugin = UserAgentPlugin()
 analytics.add(plugin: userAgentPlugin)
 ```
 */
final class UserAgentPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    var userAgent: String?
    
    init() {
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
        guard let userAgent = userAgent else { return event }
        
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        contextDict["userAgent"] = userAgent
        updatedEvent.context = contextDict.codableWrapped
        
        return updatedEvent
    }
}

// MARK: - UserAgent
extension UserAgentPlugin {
    
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
