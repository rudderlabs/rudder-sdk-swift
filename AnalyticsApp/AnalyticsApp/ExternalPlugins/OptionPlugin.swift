//
//  OptionPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 26/03/25.
//

import Foundation
import Analytics

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
        
        return updatedEvent
    }
}
