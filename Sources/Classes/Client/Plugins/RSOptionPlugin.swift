//
//  RSOptionPlugin.swift
//  RudderStack
//
//  Created by Pallab Maiti on 02/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSOptionPlugin: RSPlatformPlugin {
    let type: PluginType = .before
    var client: RSClient?
    
    var option: RSOption?
    
    required init() { }
}

extension RSClient {
    @objc
    public func setOption(_ option: RSOption) {
        if let optionPlugin = self.find(pluginType: RSOptionPlugin.self) {
            optionPlugin.option = option
        } else {
            let optionPlugin = RSOptionPlugin()
            optionPlugin.option = option
            add(plugin: optionPlugin)
        }
    }
}
