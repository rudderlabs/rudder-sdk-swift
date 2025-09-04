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

#if os(iOS)
import UIKit
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
        Task { [weak self] in
            guard let self else {
                LoggerAnalytics.debug(log: "Failed to read user agent")
                return
            }
            let ua = await self.readUserAgent()
            LoggerAnalytics.debug(log: "User Agent: \(ua)")
            self.userAgent = ua
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
    private func readUserAgent() async -> String {
#if canImport(WebKit)
        do {
            let webView = WKWebView(frame: .zero)
            guard let ua = try await webView.evaluateJavaScript("navigator.userAgent") as? String,
                  !ua.isEmpty else {  return preparedUserAgent() }
            return ua
            
        } catch {
            LoggerAnalytics.error(log: "Failed to read user agent", error: error)
            return preparedUserAgent()
        }
#else
        return preparedUserAgent()
#endif
    }
    
    private func preparedUserAgent() -> String {
        let appName = applicationName
        let separator = appName.isEmpty ? "" : " "
        
#if os(macOS)
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersion)) AppleWebKit/\(webKitVersion) (KHTML, like Gecko)\(separator)\(appName)"
        
#elseif os(iOS)
        let mobileAppName = appName.isEmpty ? "Mobile/\(mobileVersion)" : "\(appName) Mobile/\(mobileVersion)"
        
#if os(iOS)
        // iOS user agent format
        let cpuType = deviceModel == "iPhone" ? "iPhone" : "OS"
        return "Mozilla/5.0 (\(deviceModel); CPU \(cpuType) \(osVersion) like Mac OS X) AppleWebKit/\(webKitVersion) (KHTML, like Gecko) \(mobileAppName)"
#else
        // Catalyst user agent format
        return "Mozilla/5.0 (\(deviceModel); CPU OS \(osVersion) like Mac OS X) AppleWebKit/\(webKitVersion) (KHTML, like Gecko) \(mobileAppName)"
#endif
        
#else
        // watchOS, tvOS, etc.
        return "Mozilla/5.0 (Apple; CPU OS \(osVersion) like Mac OS X) AppleWebKit/\(webKitVersion) (KHTML, like Gecko)\(separator)\(appName)"
#endif
    }
}

// MARK: - Helpers
extension UserAgentPlugin {
    
    private var osVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion)_\(version.minorVersion)_\(version.patchVersion)"
    }
    
    private var applicationName: String {
        guard let bundleInfo = Bundle.main.infoDictionary,
              let appName = bundleInfo["CFBundleName"] as? String ?? bundleInfo["CFBundleDisplayName"] as? String,
              let version = bundleInfo["CFBundleShortVersionString"] as? String else {
            return ""
        }
        return "\(appName)/\(version)"
    }
    
    private var deviceModel: String {
#if os(iOS)
        let model = UIDevice.current.model
        
        // Normalize device model names
        if model.contains("iPhone") {
            return "iPhone"
        } else if model.contains("iPad") {
            return "iPad"
        } else {
            // Default to iPad for unknown devices (Catalyst)
            return "iPad"
        }
#else
        return "iPad"
#endif
    }
    
    private var webKitVersion: String {
        // Try to get actual WebKit version from bundle first
        if let webKitBundle = Bundle(identifier: "com.apple.WebKit"),
           let version = webKitBundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        
        return "605.1.15"
    }
    
    private var mobileVersion: String { "15E148" }
}
