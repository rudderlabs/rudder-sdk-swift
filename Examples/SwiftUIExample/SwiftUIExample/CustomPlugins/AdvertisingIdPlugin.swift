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
 This plugin automatically adds the device's advertising ID (IDFA) to all analytics events when the user has granted tracking permission. This is useful for advertising attribution and personalized ads.
 
 ## What it does:
    - Checks if the user has authorized app tracking
    - Gets the device's advertising identifier (IDFA)
    - Adds the advertising ID to the device context of every event
    - Marks ad tracking as enabled in the event data
 
 ## Privacy:
 This plugin respects user privacy by only adding the advertising ID when the user has explicitly granted tracking permission through iOS App Tracking Transparency.
 
 ## Usage:
 ```swift
 // Add the plugin to your analytics instance
 let advertisingPlugin = AdvertisingIdPlugin()
 analytics.add(plugin: advertisingPlugin)
 
 // The plugin will automatically add advertising ID to all events
 // when tracking is authorized
 ```
 - Important: Make sure to request tracking permission before expecting advertising ID.
 */
class AdvertisingIdPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    /** Function to get the current tracking authorization status */
    var trackingAuthorizationStatus: () -> ATTrackingManager.AuthorizationStatus = {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    
    /** Function to get the device's advertising identifier */
    var getAdvertisingId: () -> String? = {
        return ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    /** Called by RudderStackAnalytics when the plugin is added to the analytics instance. */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /**
     Intercepts every analytics event and adds advertising ID if tracking is authorized
      
     This method is called automatically for every event before it's sent.
     It checks if tracking is authorized and adds the advertising ID to the event's device context.
     */
    func intercept(event: any Event) -> (any Event)? {
        // Only add advertising ID if tracking is authorized and ID is available
        guard trackingAuthorizationStatus() == .authorized, let advertisingId = getAdvertisingId() else { return event }
        
        var updatedEvent = event
        // Get the existing context or create a new one
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        // Get the existing device information or create a new dictionary
        var deviceInfoDict = contextDict["device"] as? [String: Any] ?? [:]
        // Add the advertising ID and mark tracking as enabled
        deviceInfoDict["advertisingId"] = advertisingId
        deviceInfoDict["adTrackingEnabled"] = true
        
        // Update the device info in the context
        contextDict["device"] = deviceInfoDict
        
        // Apply the updated context back to the event
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}
