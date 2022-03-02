//
//  RSIntegrationPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSIntegrationPlugin: RSPlatformPlugin {
    let type: PluginType = .before
    var client: RSClient?
        
    func execute<T: RSMessage>(event: T?) -> T? {
        guard var workingEvent = event else { return event }
        if workingEvent.option?.integrations?.isEmpty == true {
            if let optionPlugin = client?.find(pluginType: RSOptionPlugin.self) {
                if let integrations = optionPlugin.option?.integrations {
                    workingEvent.integrations = integrations
                } else {
                    workingEvent.integrations = ["All": true]
                }
            }
        }
        if workingEvent.option?.integrations?["All"] == nil {
            workingEvent.integrations = workingEvent.option?.integrations
            workingEvent.integrations?["All"] = true
        }
        return workingEvent
    }
}
