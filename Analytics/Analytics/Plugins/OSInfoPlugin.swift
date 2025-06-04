//
//  OSInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 04/12/24.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - OSInfoPlugin
/**
 A plugin created to append OS information to the event context.
 */
final class OSInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["os": self.preparedOSInfo])
    }
    
    private var preparedOSInfo: [String: Any] = {
#if os(iOS)
        let name = UIDevice.current.systemName
        let versionString = UIDevice.current.systemVersion

#elseif os(macOS)
        let name = "macOS"
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
#elseif os(watchOS)
        let name = WKInterfaceDevice.current().systemName
        let versionString = WKInterfaceDevice.current().systemVersion
#endif
        return ["name": name, "version": versionString]
    }()
}
