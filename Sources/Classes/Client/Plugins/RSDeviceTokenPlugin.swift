//
//  RSDeviceTokenPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSDeviceTokenPlugin: PlatformPlugin {
    let type = PluginType.before
    var analytics: RSClient?
    
    var token: String?

    required init() { }
    
    func execute<T: RSMessage>(event: T?) -> T? {
        guard var workingEvent = event else { return event }
        if var context = workingEvent.context, let token = token {
            context[keyPath: "device.token"] = token
            workingEvent.context = context
        }
        return workingEvent
    }
}

extension RSClient {
    func setDeviceToken(_ token: String) {
        if let tokenPlugin = self.find(pluginType: RSDeviceTokenPlugin.self) {
            tokenPlugin.token = token
        } else {
            let tokenPlugin = RSDeviceTokenPlugin()
            tokenPlugin.token = token
            add(plugin: tokenPlugin)
        }
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}