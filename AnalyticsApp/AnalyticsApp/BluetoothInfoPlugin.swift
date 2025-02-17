//
//  BluetoothInfoPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 17/02/25.
//

import Analytics
import CoreBluetooth

// MARK: - AdvertisingIdPlugin
/**
 This class is a pre-processing plugin that retrieves the statee of bluetooth and adds it to the context of an event.
 */

class BluetoothInfoPlugin: Plugin {
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    var isBluetoothAvailable: Bool {
        return CBManager.authorization == .allowedAlways
    }
    
    func execute(event: any Message) -> (any Message)? {
        let isBluetoothAvailable = self.isBluetoothAvailable
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

