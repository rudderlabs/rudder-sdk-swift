//
//  DeviceInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/11/24.
//

import Foundation
import UIKit

// MARK: - DeviceInfoPlugin
/**
 A plugin created to append device information to the message context.
 */
final class DeviceInfoPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    var collectDeviceId = false
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.collectDeviceId = analytics.configuration.collectDeviceId
    }
    
    func execute(event: any Message) -> (any Message)? {
        return event.append(info: ["device": self.preparedDeviceInfo])
    }
}

// MARK: - Information Provider

extension DeviceInfoPlugin {
    
    var preparedDeviceInfo: [String: Any] {
        var deviceInfo = [String: Any]()
        
        deviceInfo["id"] = self.collectDeviceId ? UIDevice.current.identifierForVendor?.uuidString : nil
        deviceInfo["manufacturer"] = "Apple"
        deviceInfo["model"] = self.deviceModelIdentifier
        deviceInfo["name"] = UIDevice.current.name
        deviceInfo["type"] = UIDevice.current.systemName
        
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
