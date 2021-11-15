//
//  RSUserDefaults.swift
//  Rudder
//
//  Created by Pallab Maiti on 17/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import UIKit

class RSUserDefaults {
    static func getLastUpdatedTime() -> Int? {
        return UserDefaults.standard.lastUpdateTime
    }
    
    static func updateLastUpdatedTime(_ time: Int) {
        UserDefaults.standard.lastUpdateTime = time
    }
        
    static func getServerConfig() -> RSServerConfig? {
        return UserDefaults.standard.serverConfig
    }
    
    static func saveServerConfig(_ serverConfig: RSServerConfig) {
        UserDefaults.standard.serverConfig = serverConfig
    }
    
    static func getTraits() -> String? {
        return UserDefaults.standard.traits
    }
    
    static func saveTraits(_ traits: String?) {
        UserDefaults.standard.traits = traits
    }
    
    static func getBuildVersionCode() -> String? {
        return UserDefaults.standard.buildVersionCode
    }
    
    static func saveBuildVersionCode(_ version: String?) {
        UserDefaults.standard.buildVersionCode = version
    }
    
    static func getExternalIds() -> String? {
        return UserDefaults.standard.externalIds
    }
    
    static func saveExternalIds(_ externalIdsJson: String?) {
        UserDefaults.standard.externalIds = externalIdsJson
    }
    
    static func clearExternalIds() {
        UserDefaults.standard.externalIds = nil
    }
    
    static func getAnonymousId() -> String? {
        if let anonymousId = UserDefaults.standard.anonymousId {
            return anonymousId
        } else {
            if let anonymousId = UIDevice.current.identifierForVendor?.uuidString.lowercased() {
                saveAnonymousId(anonymousId)
                return anonymousId
            }
        }
        return nil
    }
    
    static func saveAnonymousId(_ anonymousId: String) {
        UserDefaults.standard.anonymousId = anonymousId
    }
}
