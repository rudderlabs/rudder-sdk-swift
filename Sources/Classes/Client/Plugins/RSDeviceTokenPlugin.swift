//
//  RSDeviceTokenPlugin.swift
//  RudderStack
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSDeviceTokenPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var token: String?

    required init() { }
    
    func execute<T: RSMessage>(message: T?) -> T? {
        guard var workingMessage = message else { return message }
        if var context = workingMessage.context, let token = token {
            context[keyPath: "device.token"] = token
            workingMessage.context = context
        }
        return workingMessage
    }
}

extension RSClient {
    @objc
    public func setDeviceToken(_ token: String) {
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
