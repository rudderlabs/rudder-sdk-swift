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
        deviceInfo["id"] = self.collectDeviceId ? self.macAddress("en0") : nil
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

#if os(macOS)
extension DeviceInfoPlugin {
    private func macAddress(_ bsd: String) -> String? {
        let macAddressLength = 6
        let separator = ":"
        let mibSize = 6
        let indexOffset = 1

        var length: size_t = 0
        var buffer: [CChar]

        let bsdIndex = Int32(if_nametoindex(bsd))
        guard bsdIndex != 0 else { return nil }

        let bsdData = Data(bsd.utf8)
        var managementInfoBase: [Int32] = [CTL_NET, AF_ROUTE, 0, AF_LINK, NET_RT_IFLIST, bsdIndex]

        guard sysctl(&managementInfoBase, u_int(mibSize), nil, &length, nil, 0) >= 0 else {
            return nil
        }

        buffer = [CChar](repeating: 0, count: length)
        guard sysctl(&managementInfoBase, u_int(mibSize), &buffer, &length, nil, 0) >= 0 else {
            return nil
        }

        let infoData = Data(bytes: buffer, count: length)
        let startIndex = MemoryLayout<if_msghdr>.stride + indexOffset

        guard let rangeOfToken = infoData[startIndex...].range(of: bsdData) else {
            return nil
        }

        let lower = rangeOfToken.upperBound
        let upper = lower + macAddressLength
        guard upper <= infoData.count else { return nil }

        let macAddressData = infoData[lower..<upper]
        let addressBytes = macAddressData.map { String(format: "%02x", $0) }
        return addressBytes.joined(separator: separator)
    }
}
#endif
