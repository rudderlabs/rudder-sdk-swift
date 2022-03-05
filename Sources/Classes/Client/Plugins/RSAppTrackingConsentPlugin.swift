//
//  RSAppTrackingConsentPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSAppTrackingConsentPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var appTrackingConsent: RSAppTrackingConsent?

    required init() { }
    
    func execute<T: RSMessage>(message: T?) -> T? {
        guard var workingEvent = message else { return message }
        if var context = workingEvent.context, let appTrackingConsent = appTrackingConsent {
            context[keyPath: "device.attTrackingStatus"] = appTrackingConsent.rawValue
            workingEvent.context = context
        }
        return workingEvent
    }
}

extension RSClient {
    @objc
    public func setAppTrackingConsent(_ appTrackingConsent: RSAppTrackingConsent) {
        if let appTrackingConsentPlugin = self.find(pluginType: RSAppTrackingConsentPlugin.self) {
            appTrackingConsentPlugin.appTrackingConsent = appTrackingConsent
        } else {
            let appTrackingConsentPlugin = RSAppTrackingConsentPlugin()
            appTrackingConsentPlugin.appTrackingConsent = appTrackingConsent
            add(plugin: appTrackingConsentPlugin)
        }
    }
}
