//
//  PayloadCapturePlugin.swift
//  SwiftUIExampleApp
//
//  Created by Satheesh Kannan on 01/04/26.
//

import Foundation
import RudderStackAnalytics

/// Intercepts every outgoing event and publishes its JSON payload for display.
final class PayloadCapturePlugin: Plugin {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    
    var onPayloadCaptured: ((String) -> Void)?
    
    func intercept(event: any Event) -> (any Event)? {
        if let jsonString = event.jsonString {
            onPayloadCaptured?(jsonString)
        }
        return event
    }
}
