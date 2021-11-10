//
//  RSConstants.swift
//  Rudder
//
//  Created by Pallab Maiti on 04/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSConstants {
    static let RSConfigRefreshInterval: Int = 2
    static let RSDataPlaneUrl: String = "https://hosted.rudderlabs.com"
    static let RSFlushQueueSize: Int = 30
    static let RSDBCountThreshold: Int = 10000
    static let RSSleepTimeout: Int = 10
    static let RSControlPlaneUrl: String = "https://api.rudderlabs.com"
    static let RSTrackLifeCycleEvents: Bool = true
    static let RSRecordScreenViews: Bool = false
    static let RSVersion: String = "1.0.21"
    static let TAG = "RSStack"
    static let RSPrefsKey: String = "rl_prefs"
    static let RSServerConfigKey: String = "rl_server_config"
    static let RSServerLastUpdatedKey: String = "rl_server_last_updated"
    static let RSTraitsKey: String = "rl_traits"
    static let RSApplicationInfoKey: String = "rl_application_info_key"
    static let RSExternalIdKey: String =  "rl_external_id"
    static let RSAnonymousIdKey: String =  "rl_anonymous_id"
    static let MAX_EVENT_SIZE: UInt = 32 * 1024
    static let MAX_BATCH_SIZE: UInt = 500 * 1024
}
