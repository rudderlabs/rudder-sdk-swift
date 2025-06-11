//
//  SetPushTokenPlugin.swift
//  AnalyticsApp
//
//  Created by Satheesh Kannan on 11/06/25.
//

import Foundation
import Analytics

class SetPushTokenPlugin: Plugin {
    let pushToken: String
    var pluginType: PluginType = .preProcess
    var analytics: AnalyticsClient?
    
    init(pushToken: String) {
        self.pushToken = pushToken
    }
    
    func setup(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        var deviceInfoDict = contextDict["device"] as? [String: Any] ?? [:]
        deviceInfoDict["token"] = pushToken
        contextDict["device"] = deviceInfoDict
        
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}
