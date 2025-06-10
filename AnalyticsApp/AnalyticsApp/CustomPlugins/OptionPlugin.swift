//
//  OptionPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 26/03/25.
//

import Foundation
import Analytics

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
        guard let option else { return event }
        
        var updatedEvent = event
        
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        option.customContext?.forEach { contextDict[$0.key] = $0.value }
        
        if let ids = option.externalIds?.compactMap({ ["id": $0.id, "type": $0.type] }) {
            var externalIdsArray = contextDict["externalId"] as? [[String: Any]] ?? []
            externalIdsArray.append(contentsOf: ids)
            contextDict["externalId"] = externalIdsArray
        }
        updatedEvent.context = contextDict.codableWrapped
        
        var integrationsDict = updatedEvent.integrations?.rawDictionary ?? [:]
        option.integrations?.forEach { integrationsDict[$0.key] = $0.value }
        updatedEvent.integrations = integrationsDict.codableWrapped
        
        return updatedEvent
    }
}
