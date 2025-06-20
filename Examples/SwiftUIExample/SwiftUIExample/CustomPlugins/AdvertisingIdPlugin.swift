//
//  AdvertisingIdPlugin.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 20/01/25.
//

import RudderStackAnalytics
import AdSupport
import AppTrackingTransparency

// MARK: - AdvertisingIdPlugin
/**
 This class is a pre-processing plugin that retrieves the IDFA (Identifier for Advertisers) when tracking is authorized and adds it to the context of an event.
 */
class AdvertisingIdPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    var trackingAuthorizationStatus: () -> ATTrackingManager.AuthorizationStatus = {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    var getAdvertisingId: () -> String? = {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard trackingAuthorizationStatus() == .authorized, let advertisingId = getAdvertisingId() else { return event }
        
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        var deviceInfoDict = contextDict["device"] as? [String: Any] ?? [:]
        deviceInfoDict["advertisingId"] = advertisingId
        deviceInfoDict["adTrackingEnabled"] = true
        
        contextDict["device"] = deviceInfoDict
        
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}
