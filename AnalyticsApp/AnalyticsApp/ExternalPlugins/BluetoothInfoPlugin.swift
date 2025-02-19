//
//  BluetoothInfoPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 17/02/25.
//

import Analytics
import CoreBluetooth

// MARK: - BluetoothInfoPlugin
/**
 This class is a preprocessing plugin that retrieves the Bluetooth state and adds it to an event’s context.
 */

class BluetoothInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    var bluetoothAuthorizationStatus: () -> CBManagerAuthorization = {
        return CBManager.authorization
    }
    
    func intercept(event: any Message) -> (any Message)? {
        let isBluetoothAvailable = self.bluetoothAuthorizationStatus() == .allowedAlways
        guard isBluetoothAvailable else { return event }
        
        var networkContent = [String: Any]()
        if let networkInfo = event.context?["network"]?.value as? [String: Any] {
            networkInfo.forEach { networkContent[$0.key] = $0.value }
        }
        
        // Add the bluetooth value to the network context
        networkContent["bluetooth"] = isBluetoothAvailable
        
        return event.addToContext(info: ["network": networkContent])
    }
}

