//
//  RSEventFilterPlugin.swift
//  Rudder
//
//  Created by Pallab Maiti on 07/03/22.
//  Copyright © 2022 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSEventFilterPlugin: RSPlatformPlugin {
    let type = PluginType.before
    var client: RSClient?
    
    var optOutStatus: Bool?

    required init() { }
    
    func execute<T: RSMessage>(message: T?) -> T? {
        
        return message
    }
}
