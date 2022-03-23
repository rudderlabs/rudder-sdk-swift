//
//  RSAnonymousIdPlugin.swift
//  RudderStack
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSAnonymousIdPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var anonymousId = RSUserDefaults.getAnonymousId()

    required init() { }
    
    func execute<T: RSMessage>(message: T?) -> T? {
        guard var workingMessage = message else { return message }
        if let anonymousId = anonymousId {
            workingMessage.anonymousId = anonymousId
            if var context = workingMessage.context {
                context[keyPath: "traits.anonymousId"] = anonymousId
                workingMessage.context = context
            }
        }
        return workingMessage
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
