//
//  RSUserDefaults.swift
//  RudderStack
//
//  Created by Pallab Maiti on 17/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
import UIKit
#endif
import Foundation

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
    
    static func getApplicationVersion() -> String? {
        return UserDefaults.standard.applicationVersion
    }
    
    static func saveApplicationVersion(_ version: String?) {
        UserDefaults.standard.applicationVersion = version
    }
    
    static func getApplicationBuild() -> String? {
        return UserDefaults.standard.applicationBuild
    }
    
    static func saveApplicationBuild(_ build: String?) {
        UserDefaults.standard.applicationBuild = build
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
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            if let anonymousId = UIDevice.current.identifierForVendor?.uuidString.lowercased() {
                saveAnonymousId(anonymousId)
                return anonymousId
            }
            #endif
        }
        return nil
    }
    
    static func saveAnonymousId(_ anonymousId: String) {
        UserDefaults.standard.anonymousId = anonymousId
    }
    
    static func getOptStatus() -> Bool? {
        return UserDefaults.standard.optStatus
    }

    static func saveOptStatus(_ optStatus: Bool) {
        UserDefaults.standard.optStatus = optStatus
    }
    
    static func getOptInTime() -> Int? {
        return UserDefaults.standard.optInTime
    }
    
    static func updateOptInTime(_ optInTime: Int?) {
        UserDefaults.standard.optInTime = optInTime
    }
    
    static func getOptOutTime() -> Int? {
        return UserDefaults.standard.optOutTime
    }
    
    static func updateOptOutTime(_ optOutTime: Int?) {
        UserDefaults.standard.optOutTime = optOutTime
    }
}
