//
//  IntegrationsHolderPlugin.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 12/10/25.
//

import Foundation
import Combine

class IntegrationsManagementPlugin: Plugin {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    var integrationsPluginChain: PluginChain?
    var integrationPluginStores: [String: IntegrationPluginStore] = [:]
    
    // TODO: - Create list of defaultPlugins
    var defaultPlugins: [Plugin] = []
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        self.integrationsPluginChain = PluginChain(analytics: analytics)
        
        // TODO: - Add sourceConfig observer logic
    }
    
    // TODO: - Add logic to add/remove integration plugins and to notify callbacks
    
    deinit {
        self.integrationPluginStores.removeAll()
    }
}
