//
//  IntegrationPluginStore.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation

/**
 Stores the state of an integration plugin
 */
class IntegrationPluginStore {
    var analytics: Analytics?
    var pluginChain: PluginChain?
    var destinationReadyCallbacks: [IntegrationCallback] = []
    var isStandardIntegration: Bool = true
    var isDestinationReady = false
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.pluginChain = PluginChain(analytics: analytics)
    }
    
    deinit {
        self.pluginChain?.removeAll()
        self.pluginChain = nil
        self.destinationReadyCallbacks.removeAll()
    }
}
