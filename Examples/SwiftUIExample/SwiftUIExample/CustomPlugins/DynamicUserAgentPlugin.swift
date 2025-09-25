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
 Supported on iOS, macOS, and tvOS only (requires WebKit framework).
 
 ## Usage:
 ```swift
 // Create and add the plugin
 let userAgentPlugin = DynamicUserAgentPlugin()
 analytics.add(plugin: userAgentPlugin)
 ```
 
 **Note**: Early events may be sent without User Agent since it's fetched asynchronously.
 For production, pre-fetch before plugin initialization:
 
 **Recommended:**
 ```swift
 // Pre-fetch User Agent before SDK initialization
 let userAgent = await DynamicUserAgentPlugin.readUserAgent()
 let userAgentPlugin = DynamicUserAgentPlugin(precomputedUserAgent: userAgent)
 
 // Initialize analytics with the plugin
 let analytics = Analytics(configuration: configuration)
 analytics.add(plugin: userAgentPlugin)
 ```
 
 This ensures the User Agent is available immediately when the plugin starts intercepting events,
 providing consistent behavior across all tracked events.
 */
final class DynamicUserAgentPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    var userAgent: String?
    
    /**
     Read user agent on initialization on main thread.
     
     - Note: This async operation may not complete before events start being processed, potentially causing early events to be sent without User Agent information. For production use, consider pre-fetching the User Agent before plugin initialization.
     */
    init() {
        Task { @MainActor [weak self] in
            guard let self else {
                LoggerAnalytics.debug("Plugin deallocated before reading user agent")
                return
            }
            self.userAgent = await Self.readUserAgent()
        }
    }
    
    /**
     Initializes the plugin with a pre-computed User Agent string.
     
     - Parameter precomputedUserAgent: The User Agent string to use for all events.
     - Note: This initializer is recommended for production use to ensure consistent User Agent availability.
     */
    init(precomputedUserAgent: String?) {
        self.userAgent = precomputedUserAgent
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
    static func readUserAgent() async -> String? {
#if canImport(WebKit)
        do {
            let webView = WKWebView(frame: .zero)
            guard let ua = try await webView.evaluateJavaScript("navigator.userAgent") as? String,
                  !ua.isEmpty else {  return nil }
            LoggerAnalytics.debug("User Agent: \(ua)")
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
