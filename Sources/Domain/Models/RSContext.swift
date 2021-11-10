//
//  RSContext.swift
//  Rudder
//
//  Created by Pallab Maiti on 05/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

@objc open class RSContext: NSObject {
    var app: RSApp
    var traits: [String: Any]?
    var library: RSLibraryInfo
    var osInfo: RSOSInfo
    var screenInfo: RSScreenInfo
    var userAgent: String?
    var locale: String
    var device: RSDeviceInfo
    var network: RSNetwork
    var timezone: String
    var externalIds: [[String: Any]]?
    
    override init() {
        app = RSApp()
        device = RSDeviceInfo()
        library = RSLibraryInfo()
        osInfo = RSOSInfo()
        screenInfo = RSScreenInfo()
        userAgent = RSUtils.userAgent()
        locale = RSUtils.getLocale()
        network = RSNetwork()
        timezone = NSTimeZone.local.identifier
        
        externalIds = nil
        traits = nil
        
        if let traitsJson = UserDefaults.standard.traits {
            do {
                if let dict = try JSONSerialization.jsonObject(with: Data(traitsJson.utf8), options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    traits = dict
                }
            } catch {
                traits = RSUtils.createTraits()
            }
        } else {
            traits = RSUtils.createTraits()
        }
        
        if let externalIdsJson = UserDefaults.standard.externalIds {
            do {
                if let serializedExternalIds = try JSONSerialization.jsonObject(with: Data(externalIdsJson.utf8), options: JSONSerialization.ReadingOptions.mutableContainers) as? [[String: Any]] {
                    externalIds = serializedExternalIds
                }
            } catch { }
        }
    }
    
    func saveTraits() {
        if let traits = traits {
            do {
                let traitsData = try JSONSerialization.data(withJSONObject: traits, options: JSONSerialization.WritingOptions.prettyPrinted)
                RSUserDefaults.saveTraits(String(data: traitsData, encoding: .utf8))
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func updateTraits(_ traits: RSTraits) {
        let updatedTraits = traits
        updatedTraits.anonymousId = UserDefaults.standard.anonymousId
        self.traits = updatedTraits.dictionary()
    }
    
    func updateExternalIds(_ externalIds: [[String: Any]]) {
        self.externalIds = externalIds
        do {
            let externalIdData = try JSONSerialization.data(withJSONObject: self.externalIds!, options: .prettyPrinted)
            RSUserDefaults.saveExternalIds(String(data: externalIdData, encoding: .utf8))
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func dict() -> [String: Any] {
        var tempDict: [String: Any] = [:]
        tempDict["app"] = app.dict()
        tempDict["traits"] = traits
        tempDict["library"] = library.dict()
        tempDict["os"] = osInfo.dict()
        tempDict["screen"] = screenInfo.dict()
        if userAgent != nil {
            tempDict["userAgent"] = userAgent
        }
        tempDict["locale"] = locale
        tempDict["device"] = device.dict()
        tempDict["network"] = network.dict()
        tempDict["timezone"] = timezone
        tempDict["externalId"] = externalIds
        return tempDict
    }
    
    @objc public func putDeviceToken(_ deviceToken: String) {
        device.token = deviceToken
    }
    
    @objc public func putAdvertisementId(_ idfa: String) {
        // This isn't ideal.  We're doing this because we can't actually check if IDFA is enabled on
        // the customer device.  Apple docs and tests show that if it is disabled, one gets back all 0's.
        logDebug("IDFA: \(idfa)")
        let adTrackingEnabled: Bool = idfa == "00000000-0000-0000-0000-000000000000"
        device.adTrackingEnabled = adTrackingEnabled
        if adTrackingEnabled {
            device.advertisingId = idfa
        }
    }
    
    @objc public func putAppTrackingConsent(_ att: RSATT) {
        device.attTrackingStatus = att
    }
}
