//
//  StaticUserAgentPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 04/09/25.
//

import Foundation
import RudderStackAnalytics

#if os(iOS)
import UIKit
#endif

// MARK: - StaticUserAgentPlugin
/**
 A plugin that adds static User Agent information to the event payload.
 
 ## Usage:
 ```swift
 // Create and add the plugin
 let userAgentPlugin = StaticUserAgentPlugin()
 analytics.add(plugin: userAgentPlugin)
 ```
 */
final class StaticUserAgentPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    var userAgent: String?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.userAgent = self.readUserAgent()
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
extension StaticUserAgentPlugin {
    
    /**
     Reads the User Agent string based on the current platform.
     
     - Returns: The User Agent string.
     - Note: This method can be called from any thread.
     */
    func readUserAgent() -> String {
        let appName = applicationName
        let separator = appName.isEmpty ? "" : " "
        
#if os(macOS)
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X \(osVersion)) AppleWebKit/\(webKitVersion) (KHTML, like Gecko)\(separator)\(appName)"
        
#elseif os(iOS) || targetEnvironment(macCatalyst)
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
extension StaticUserAgentPlugin {
    
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
    
    private var webKitVersion: String { "605.1.15" }
    
    private var mobileVersion: String { "15E148" }
}
