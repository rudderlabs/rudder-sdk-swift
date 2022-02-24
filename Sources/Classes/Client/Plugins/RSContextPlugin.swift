//
//  RSContextPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSContextPlugin: PlatformPlugin {
    let type: PluginType = .before
    var analytics: RSClient?
    
    internal var staticContext = staticContextData()
    internal static var device = VendorSystem.current
    
    func execute<T: RSMessage>(event: T?) -> T? {
        guard var workingEvent = event else { return event }        
        var context = staticContext
        insertDynamicPlatformContextData(context: &context)
        workingEvent.context = context
        return workingEvent
    }
    
    internal static func staticContextData() -> [String: Any] {
        var staticContext = [String: Any]()
        
        // library name
        staticContext["library"] = [
            "name": "rudder_ios_library",
            "version": RSConstants.RSVersion
        ]
        
        // app info
        let info = Bundle.main.infoDictionary
        staticContext["app"] = [
            "name": info?["CFBundleDisplayName"] ?? "",
            "version": info?["CFBundleShortVersionString"] ?? "",
            "build": info?["CFBundleVersion"] ?? "",
            "namespace": Bundle.main.bundleIdentifier ?? ""
        ]
        insertStaticPlatformContextData(context: &staticContext)        
        return staticContext
    }
    
    internal static func insertStaticPlatformContextData(context: inout [String: Any]) {
        // device
        let device = Self.device
        
        let deviceInfo = [
            "manufacturer": device.manufacturer,
            "type": device.type,
            "model": device.model,
            "name": device.name,
            "id": device.identifierForVendor ?? ""
        ]
        
        // "token" handled in DeviceToken.swift
        context["device"] = deviceInfo
        // os
        context["os"] = [
            "name": device.systemName,
            "version": device.systemVersion
        ]
        // screen
        let screen = device.screenSize
        context["screen"] = [
            "width": screen.width,
            "height": screen.height,
            "density": screen.density
        ]
        // locale
        if !Locale.preferredLanguages.isEmpty {
            context["locale"] = Locale.preferredLanguages[0]
        }
        // timezone
        context["timezone"] = TimeZone.current.identifier
    }

    internal func insertDynamicPlatformContextData(context: inout [String: Any]) {
        let device = Self.device
        
        // network
        let status = device.connection
        
        var cellular = false
        var wifi = false
        var bluetooth = false
        
        switch status {
        case .online(.cellular):
            cellular = true
        case .online(.wifi):
            wifi = true
        case .online(.bluetooth):
            bluetooth = true
        default:
            break
        }
        
        // network connectivity
        context["network"] = [
            "bluetooth": bluetooth,
            "cellular": cellular,
            "wifi": wifi,
            "carrier": device.carrier
        ]
    }

}
