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
        if let optionPlugin = client?.find(pluginType: RSOptionPlugin.self) {
            if let integrations = optionPlugin.option?.integrations {
                workingEvent.integrations = integrations
                if integrations["All"] == nil {
                    workingEvent.integrations?["All"] = true
                }
            } else {
                workingEvent.integrations = ["All": true]
            }
        } else {
            workingEvent.integrations = ["All": true]
        }
        return workingEvent
    }
}
