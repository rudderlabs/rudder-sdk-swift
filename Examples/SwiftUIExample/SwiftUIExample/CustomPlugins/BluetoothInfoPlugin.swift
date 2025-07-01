//
//  BluetoothInfoPlugin.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 17/02/25.
//

import RudderStackAnalytics
import CoreBluetooth

// MARK: - BluetoothInfoPlugin
/**
 This plugin automatically adds Bluetooth availability information to all analytics events. It checks if the app has permission to use Bluetooth and includes this information in the network context of each event.
 
 ## What it does:
    - Checks if the app has Bluetooth permissions
    - Adds Bluetooth availability status to the network context of events
    - Only includes Bluetooth info when permission is granted
 
 ## Privacy:
 This plugin respects user privacy by only checking Bluetooth authorization status, not scanning for or connecting to actual Bluetooth devices.
 
 ## Usage:
 ```swift
 // Add the plugin to your analytics instance
 let bluetoothPlugin = BluetoothInfoPlugin()
 analytics.add(plugin: bluetoothPlugin)
 
 // The plugin will automatically add Bluetooth info to all events when Bluetooth permission is granted
 ```
 ## Event Context:
 When Bluetooth is available, events will include:
 ```json
 {
    "context": {
        "network": {
            "bluetooth": true
        }
    }
 }
  ```
 */

class BluetoothInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    /** Called by RudderStackAnalytics when the plugin is added to the analytics instance */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /** Function to get the current Bluetooth authorization status */
    var bluetoothAuthorizationStatus: () -> CBManagerAuthorization = {
        return CBManager.authorization
    }
    
    /**
     Intercepts every analytics event and adds Bluetooth availability if authorized
      
     This method is called automatically for every event before it's sent. It checks if Bluetooth permission is granted and adds the availability status to the network context of the event.
     */
    func intercept(event: any Event) -> (any Event)? {
        // Check if Bluetooth is available (permission granted)
        let isBluetoothAvailable = self.bluetoothAuthorizationStatus() == .allowedAlways
        // If Bluetooth is not available, return the event unchanged
        guard isBluetoothAvailable else { return event }
        
        var updatedEvent = event
        // Get the existing context or create a new one
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        // Get the existing network information or create a new dictionary
        var networkInfoDict = contextDict["network"] as? [String: Any] ?? [:]
        // Add Bluetooth availability to the network context
        networkInfoDict["bluetooth"] = isBluetoothAvailable
        contextDict["network"] = networkInfoDict
        
        // Apply the updated context back to the event
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}

