//
//  RSUserIdPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 01/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSUserIdPlugin: PlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var userId: String?

    required init() { }
    
    func execute<T: RSMessage>(event: T?) -> T? {
        guard var workingEvent = event else { return event }
        if let userId = userId {
            workingEvent.userId = userId
        }
        return workingEvent
    }
}

extension RSClient {
    internal func setUserId(_ userId: String) {
        if let userIdPlugin = self.find(pluginType: RSUserIdPlugin.self) {
            userIdPlugin.userId = userId
        } else {
            let userIdPlugin = RSUserIdPlugin()
            userIdPlugin.userId = userId
            add(plugin: userIdPlugin)
        }
    }    
}

extension AliasMessage {
    internal func applyAlias(newId: String, client: RSClient) -> Self {
        var result: Self = self
        result.userId = newId
        if let userIdPlugin = client.find(pluginType: RSUserIdPlugin.self), let previousId = userIdPlugin.userId {
            result.previousId = previousId
        }
        return result
    }
}
