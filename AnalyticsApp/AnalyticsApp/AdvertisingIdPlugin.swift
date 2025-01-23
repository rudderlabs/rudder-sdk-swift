//
//  AdvertisingIdPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Analytics
import AdSupport
import AppTrackingTransparency

// MARK: - AdvertisingIdPlugin
/**
 This class is a pre-processing plugin that retrieves the IDFA (Identifier for Advertisers) when tracking is authorized and adds it to the context of an event.
 */
class AdvertisingIdPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    var trackingAuthorizationStatus: () -> ATTrackingManager.AuthorizationStatus = {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    var getAdvertisingId: () -> String? = {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        guard trackingAuthorizationStatus() == .authorized, let advertisingId = getAdvertisingId() else {
            return event
        }
        
        var deviceContent = [String: Any]()
        if let deviceInfo = event.context?["device"]?.value as? [String: Any] {
            deviceInfo.forEach { deviceContent[$0.key] = $0.value }
        }
        
        // Add the IDFA to the device context
        deviceContent["advertisingId"] = advertisingId
        deviceContent["adTrackingEnabled"] = true
        
        return event.addToContext(info: ["device": deviceContent])
    }
}
