//
//  OptionPlugin.swift
//  SwiftUIApp
//
//  Created by Satheesh Kannan on 26/03/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - OptionPlugin
/**
 This class is a processing plugin that updates option values of any event.
 */

final class OptionPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: AnalyticsClient?
    var option: RudderOption?
    
    init(option: RudderOption) {
        self.option = option
    }
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        guard self.option != nil else { return event }
        var updatedEvent = event
        
        self.addCustomContext(&updatedEvent)
        self.addExternalIds(&updatedEvent)
        self.addIntegrations(&updatedEvent)
        
        return updatedEvent
    }
}

// MARK: - Helpers

extension OptionPlugin {
    
    func addCustomContext(_ event: inout any Event) {
        var contextDict = event.context?.rawDictionary ?? [:]
        self.option?.customContext?.forEach { contextDict[$0.key] = $0.value }
        event.context = contextDict.codableWrapped
    }
    
    func addExternalIds( _ event: inout any Event) {
        var contextDict = event.context?.rawDictionary ?? [:]
        if let ids = self.option?.externalIds?.map({ ["id": $0.id, "type": $0.type] }) {
            var externalIdsArray = contextDict["externalId"] as? [[String: Any]] ?? []
            
            // Merge option's externalIds into existing externalIds
            externalIdsArray.append(contentsOf: ids)
            contextDict["externalId"] = externalIdsArray
        }
        event.context = contextDict.codableWrapped
    }
    
    func addIntegrations(_ event: inout any Event) {
        var integrationsDict = event.integrations?.rawDictionary ?? [:]
        self.option?.integrations?.forEach { integrationsDict[$0.key] = $0.value }
        event.integrations = integrationsDict.codableWrapped
    }
}
