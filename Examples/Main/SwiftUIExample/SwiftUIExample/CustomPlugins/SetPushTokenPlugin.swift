//
//  SetPushTokenPlugin.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 11/06/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - SetPushTokenPlugin
/**
 A plugin that sets the push notification token in the event context.
 
 Usage:
 ```swift
 let plugin = SetPushTokenPlugin(pushToken: "your_device_token")
 analytics.add(plugin: plugin)
 ```
 This will automatically add the push token to the `device` context of all events processed by the plugin.
*/
class SetPushTokenPlugin: Plugin {
    /** The push notification token to be added to the event context. */
    let pushToken: String
    
    /** The type of plugin, set to `.preProcess`. */
    var pluginType: PluginType = .preProcess
    
    /** The analytics client instance, set during setup. */
    var analytics: Analytics?
    
    /**
     Initializes the plugin with the given push notification token.
     
     - Parameter pushToken: The device push notification token to be set in the event context.
    */
    init(pushToken: String) {
        self.pushToken = pushToken
    }
    
    /**
     Sets up the plugin with the provided analytics client.
     
     - Parameter analytics: The analytics client instance to be used by the plugin.
    */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /**
     Intercepts and modifies the event to include the push token in the device context.
     
     - Parameter event: The event to be processed.
     - Returns: The modified event with the push token added to the device context.
    */
    func intercept(event: any Event) -> (any Event)? {
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        var deviceInfoDict = contextDict["device"] as? [String: Any] ?? [:]
        deviceInfoDict["token"] = pushToken
        contextDict["device"] = deviceInfoDict
        
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}
