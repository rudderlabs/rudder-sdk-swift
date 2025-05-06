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
        
        var updatedEvent = event.addToContext(info: option.customContext ?? [:])
        updatedEvent = updatedEvent.addToIntegrations(info: option.integrations ?? [:])
        updatedEvent = updatedEvent.addExternalIds(info: option.externalIds ?? [])
        
        return updatedEvent
    }
}
