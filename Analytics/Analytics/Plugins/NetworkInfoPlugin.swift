//
//  NetworkInfoPlugin.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/12/24.
//

import Foundation
import Network

// MARK: - NetworkInfoPlugin
/**
 A plugin created to append network information to the message context.
 */
final class NetworkInfoPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    var bluetoothManager = BluetoothStatusManager()
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func execute(event: any Message) -> (any Message)? {
        return event.append(info: ["network": self.preparedNetworkInfo])
    }
    
    private var preparedNetworkInfo: [String: Any] {
        var networkInfo = [String: Any]()
        
        let (cellular, wifi) = self.checkNetworkConnectivity()
        
        networkInfo["wifi"] = wifi
        networkInfo["cellular"] = cellular
        
        if self.isBluetoothAvailable { networkInfo["bluetooth"] = true }
        
        return networkInfo
    }
}

extension NetworkInfoPlugin {
    
    func checkNetworkConnectivity() -> (cellular: Bool, wifi: Bool) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")

        var cellular = false
        var wifi = false

        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                wifi = path.usesInterfaceType(.wifi)
                
                #if os(iOS) || os(macOS) || os(watchOS)
                cellular = path.usesInterfaceType(.cellular)
                #else
                cellular = false
                #endif
            } else {
                cellular = false
                wifi = false
            }
            semaphore.signal()
        }

        monitor.start(queue: queue)
        semaphore.wait()
        monitor.cancel()

        return (cellular, wifi)
    }
    
    var isBluetoothAvailable: Bool {
        return bluetoothManager.isBluetoothEnabled
    }
}
