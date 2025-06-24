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
 This class is a preprocessing plugin that retrieves the Bluetooth state and adds it to an event’s context.
 */

class BluetoothInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: Analytics?
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    var bluetoothAuthorizationStatus: () -> CBManagerAuthorization = {
        return CBManager.authorization
    }
    
    func intercept(event: any Event) -> (any Event)? {
        let isBluetoothAvailable = self.bluetoothAuthorizationStatus() == .allowedAlways
        guard isBluetoothAvailable else { return event }
        
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        var networkInfoDict = contextDict["network"] as? [String: Any] ?? [:]
        networkInfoDict["bluetooth"] = isBluetoothAvailable
        contextDict["network"] = networkInfoDict
        
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}

