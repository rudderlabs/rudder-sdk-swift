//
//  SetATTTrackingStatusPlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 18/12/25.
//

import Foundation
import RudderStackAnalytics

// MARK: - SetATTTrackingStatusPlugin
/**
 A plugin that sets a given ATT tracking status (`attTrackingStatus`) inside `context.device`
 for every event.
 
 Set this plugin immediately after SDK initialisation, e.g.:
 
 ```swift
 analytics.add(plugin: SetATTTrackingStatusPlugin(attTrackingStatus: 3))
 ```
 
 - Parameter attTrackingStatus: Integer ATT tracking status value (0–3).
 */
class SetATTTrackingStatusPlugin: Plugin {
    /// The type of plugin, set to `.preProcess`.
    var pluginType: PluginType = .preProcess
    
    /// Analytics client
    var analytics: Analytics?
    
    /// Custom ATT tracking status value
    private let attTrackingStatus: UInt
    
    init(attTrackingStatus: UInt) {
        if attTrackingStatus > 3 {
            LoggerAnalytics.error("SetATTTrackingStatusPlugin: Invalid attTrackingStatus value: \(attTrackingStatus). Defaulting to 0.")
            self.attTrackingStatus = 0
        } else {
            self.attTrackingStatus = attTrackingStatus
        }
    }
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
    }
    
    func intercept(event: any Event) -> (any Event)? {
        return replaceATTStatus(event: event)
    }
    
    /// Applies attTrackingStatus inside context.device
    private func replaceATTStatus(event: any Event) -> any Event {
        LoggerAnalytics.debug("SetATTTrackingStatusPlugin: Setting attTrackingStatus: \(attTrackingStatus) in event context.device")
        var updatedEvent = event
        var contextDict = updatedEvent.context?.rawDictionary ?? [:]
        
        var deviceInfoDict = contextDict["device"] as? [String: Any] ?? [:]
        deviceInfoDict["attTrackingStatus"] = Int(attTrackingStatus)
        contextDict["device"] = deviceInfoDict
        
        updatedEvent.context = contextDict.codableWrapped
        return updatedEvent
    }
}
