//
//  RSAdvertisementIdPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSAdvertisingIdPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var advertisingId: String?

    required init() { }
    
    func execute<T: RSMessage>(message: T?) -> T? {
        guard var workingEvent = message else { return message }
        if var context = workingEvent.context, let advertisingId = advertisingId {
            context[keyPath: "device.advertisingId"] = advertisingId
            context[keyPath: "device.adTrackingEnabled"] = true
            workingEvent.context = context
        }
        return workingEvent
    }
}

extension RSClient {
    @objc
    public func setAdvertisingId(_ advertisingId: String) {
        if let advertisingIdPlugin = self.find(pluginType: RSAdvertisingIdPlugin.self) {
            advertisingIdPlugin.advertisingId = advertisingId
        } else {
            let advertisingIdPlugin = RSAdvertisingIdPlugin()
            advertisingIdPlugin.advertisingId = advertisingId
            add(plugin: advertisingIdPlugin)
        }
    }
}
