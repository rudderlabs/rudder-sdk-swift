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
 A plugin created to append network information to the event context.
 */
final class NetworkInfoPlugin: Plugin {
    
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    var networkInfoUtils = NetworkInfoPluginUtils()
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return event.addToContext(info: ["network": self.preparedNetworkInfo])
    }
    
    private var preparedNetworkInfo: [String: Any] {
        var networkInfo = [String: Any]()
        
        let (cellular, wifi) = self.networkInfoUtils.checkNetworkConnectivity()
        
        networkInfo["wifi"] = wifi
        networkInfo["cellular"] = cellular
        
        return networkInfo
    }
}
