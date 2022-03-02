//
//  RSAnonymousIdPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSAnonymousIdPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var anonymousId: String?

    required init() { }
    
    func execute<T: RSMessage>(event: T?) -> T? {
        guard var workingEvent = event else { return event }
        if let anonymousId = anonymousId {
            workingEvent.anonymousId = anonymousId
            if var context = workingEvent.context {
                context[keyPath: "traits.anonymousId"] = anonymousId
                workingEvent.context = context
            }
        }
        return workingEvent
    }
}

extension RSClient {
    @objc
    public func setAnonymousId(_ anonymousId: String) {
        RSUserDefaults.saveAnonymousId(anonymousId)
        if let anonymousIdPlugin = self.find(pluginType: RSAnonymousIdPlugin.self) {
            anonymousIdPlugin.anonymousId = anonymousId
        } else {
            let anonymousIdPlugin = RSAnonymousIdPlugin()
            anonymousIdPlugin.anonymousId = anonymousId
            add(plugin: anonymousIdPlugin)
        }
    }
}
