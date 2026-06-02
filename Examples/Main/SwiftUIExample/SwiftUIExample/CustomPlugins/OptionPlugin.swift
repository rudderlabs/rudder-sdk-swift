//
//  OptionPlugin.swift
//  SwiftUIExample
//
//  Created by Satheesh Kannan on 26/03/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - OptionPlugin
/**
 This plugin is to add custom options to all analytics events. It can add custom context data, external IDs, and integration settings to every event that passes through the pipeline.
 
 ## Usage:
 ```swift
 // Create options with custom data
 let options = RudderOption(integrations: ["Amplitude": true, "Mixpanel": false], customContext: ["appVersion": "1.2.3", "userTier": "premium"], externalIds: [ExternalId(type: "userId", id: "user123")])
  
 // Create and add the plugin
 let optionPlugin = OptionPlugin(option: options)
 analytics.add(plugin: optionPlugin)
 ```
 */
final class OptionPlugin: Plugin {
    var pluginType: PluginType = .onProcess
    var analytics: Analytics?
    var option: RudderOption?
    
    /** Creates a new OptionPlugin with the specified options */
    init(option: RudderOption) {
        self.option = option
    }
    
    /** Called by RudderStack when the plugin is added to the analytics instance */
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    /** Intercepts every analytics event and adds the configured options */
    func intercept(event: any Event) -> (any Event)? {
        // If no options are configured, return the event unchanged
        guard self.option != nil else { return event }
        var updatedEvent = event
        
        // Add all the configured options to the event
        self.addCustomContext(&updatedEvent)
        self.addExternalIds(&updatedEvent)
        self.addIntegrations(&updatedEvent)
        
        return updatedEvent
    }
}

// MARK: - Helpers

extension OptionPlugin {
    
    /**
     Adds custom context data to the event
     
     - Parameter event: The event to modify (passed by reference)
     */
    func addCustomContext(_ event: inout any Event) {
        var contextDict = event.context?.rawDictionary ?? [:]
        self.option?.customContext?.forEach { contextDict[$0.key] = $0.value }
        event.context = contextDict.codableWrapped
    }
    
    /**
     Adds external IDs to the event for linking with other systems
      
     - Parameter event: The event to modify (passed by reference)
     */
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
    
    /**
     Adds integration settings to control event delivery
            
     - Parameter event: The event to modify (passed by reference)
     */
    func addIntegrations(_ event: inout any Event) {
        var integrationsDict = event.integrations?.rawDictionary ?? [:]
        self.option?.integrations?.forEach { integrationsDict[$0.key] = $0.value }
        event.integrations = integrationsDict.codableWrapped
    }
}
