//
//  AdvertisingIdPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 20/01/25.
//

import Analytics
import AdSupport
import AppTrackingTransparency

class AdvertisingIdPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        guard let advertisingId = self.advertisementId else { return event }
        
        var deviceContent = [String: Any]()
        if let deviceInfo = event.context?["device"]?.value as? [String: Any] {
            deviceInfo.forEach { deviceContent[$0.key] = $0.value }
        }
        
        // Add the IDFA to the device context
        deviceContent["advertisingId"] = advertisingId
        return event.addToContext(info: ["device": deviceContent])
    }
    
    var advertisementId: String? {
        guard ATTrackingManager.trackingAuthorizationStatus == .authorized else { return nil }
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
}
