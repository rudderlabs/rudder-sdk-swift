//
//  DeviceInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/11/24.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

// MARK: - DeviceInfoPlugin
/**
 A plugin created to append device information to the event context.
 */
final class DeviceInfoPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    var collectDeviceId = false
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.collectDeviceId = analytics.configuration.collectDeviceId
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["device": self.preparedDeviceInfo])
    }
}

// MARK: - Information Provider

extension DeviceInfoPlugin {
    
    var preparedDeviceInfo: [String: Any] {
        var deviceInfo = [String: Any]()
        
#if os(iOS)
        let device = UIDevice.current
        deviceInfo["id"] = self.collectDeviceId ? device.identifierForVendor?.uuidString : nil
        deviceInfo["name"] = device.name
        deviceInfo["type"] = device.systemName
        
#elseif os(macOS)
        let device = Host.current()
        deviceInfo["id"] = self.collectDeviceId ? ProcessInfo.processInfo.hostName : nil
        deviceInfo["name"] = device.localizedName ?? "Mac"
        deviceInfo["type"] = "macOS"
        
#elseif os(watchOS)
        let device = WKInterfaceDevice.current()
        deviceInfo["id"] = self.collectDeviceId ? device.identifierForVendor?.uuidString : nil
        deviceInfo["name"] = device.name
        deviceInfo["type"] = "watchOS"
#endif
        deviceInfo["manufacturer"] = "Apple"
        deviceInfo["model"] = self.deviceModelIdentifier
        
        return deviceInfo
    }
    
    var deviceModelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.compactMap { value -> String? in
            guard let value = value.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
        return identifier
    }
}
