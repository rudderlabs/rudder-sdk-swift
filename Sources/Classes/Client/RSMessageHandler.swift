//
//  RSMessageHandler.swift
//  Rudder
//
//  Created by Pallab Maiti on 27/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation
import UIKit

class RSMessageHandler {
    private let databaseManager: RSDatabaseManager    
    private let syncQueue = DispatchQueue(label: "storage.rudder.com")
    
    init() {
        databaseManager = RSDatabaseManager()
    }
        
    /*func handleTrackEvent(_ eventName: String, properties: [String: Any]? = nil, options: RSOption? = nil) {
        guard !RSClient.getOptStatus() else {
            return
        }
        let message = RSMessage(type: .track)
        message.event = eventName
        message.properties = properties
        message.option = options
        processMessage(message)
    }
    
    func handleScreenEvent(_ screenName: String, properties: [String: Any]? = nil, options: RSOption? = nil) {
        guard !RSClient.getOptStatus() else {
            return
        }
        let message = RSMessage(type: .screen)
        message.event = screenName
        if var properties = properties {
            properties["name"] = screenName
            message.properties = properties
        }
        message.option = options
        processMessage(message)
    }
    
    func handleGroupEvent(_ groupId: String, traits: [String: Any]? = nil, options: RSOption? = nil) {
        guard !RSClient.getOptStatus() else {
            return
        }
        let message = RSMessage(type: .group)
        message.groupId = groupId
        message.traits = traits
        message.option = options
        processMessage(message)
    }
    
    func handleAlias(_ newId: String, options: RSOption? = nil) {
        guard !RSClient.getOptStatus() else {
            return
        }
        let message = RSMessage(type: .alias)
        message.userId = newId
        message.option = options
        let context = RSClient.shared.eventManager.cachedContext
        var traits = context?.traits
        var prevId: String?
        prevId = traits?["userId"] as? String
        if prevId == nil {
            prevId = traits?["id"] as? String
        }
        
        if prevId != nil {
            message.previousId = prevId
        }
        traits?["id"] = newId
        traits?["userId"] = newId
        
        RSClient.shared.eventManager.cachedContext?.traits = traits
        RSClient.shared.eventManager.cachedContext?.saveTraits()
        message.traits = traits
        processMessage(message)
    }
    
    func handleIdentify(_ userId: String, traits: [String: Any]? = nil, options: RSOption? = nil) {
        guard !RSClient.getOptStatus() else {
            return
        }
        let message = RSMessage(type: .identify)
        message.event = RSMessageType.identify.rawValue
        message.userId = userId
        message.option = options
        if let traits = traits {                        
            let traitsCopy = RSTraits(dict: traits)
            traitsCopy.userId = userId
            RSClient.shared.eventManager.cachedContext?.updateTraits(traitsCopy)
        }
        if let options = options, let externalIds = options.externalIds {
            RSClient.shared.eventManager.cachedContext?.updateExternalIds(externalIds)
        }
        message.context = RSClient.shared.eventManager.cachedContext
        processMessage(message)
    }
    
    func processMessage(_ message: RSMessage) {        
        guard RSClient.shared.eventManager.isSDKEnabled else {
            return
        }
        if message.integrations?.isEmpty == true, let options = RSClient.shared.eventManager.options, let integrations = options.integrations, !integrations.isEmpty {
            message.integrations = integrations            
        }
        message.isAll = true
        factoryDumpManager.makeFactoryDump(message)
        dump(message: message)
    }
    
    func dump(message: RSMessage) {
        do {
            let jsonObject = message.toDict()
            if JSONSerialization.isValidJSONObject(jsonObject) {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    logDebug("dump: \(jsonString)")
                    if jsonString.getUTF8Length() > RSConstants.MAX_EVENT_SIZE {
                        logError("dump: Event size exceeds the maximum permitted event size \(RSConstants.MAX_EVENT_SIZE)")
                        return
                    }
                    RSClient.shared.eventManager.databaseManager?.saveEvent(jsonString)
                } else {
                    logError("dump: Can not convert to JSON")
                }
            } else {
                logError("dump: Not a valid JSON object")
            }
        } catch {
            logError("dump: \(error.localizedDescription)")
        }
    }*/
    
    func write(_ message: RSMessage) {
        syncQueue.sync {
            do {
                let jsonObject = message.toDict()
                if JSONSerialization.isValidJSONObject(jsonObject) {
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        logDebug("dump: \(jsonString)")
                        if jsonString.getUTF8Length() > RSConstants.MAX_EVENT_SIZE {
                            logError("dump: Event size exceeds the maximum permitted event size \(RSConstants.MAX_EVENT_SIZE)")
                            return
                        }
                        databaseManager.saveEvent(jsonString)
                    } else {
                        logError("dump: Can not convert to JSON")
                    }
                } else {
                    logError("dump: Not a valid JSON object")
                }
            } catch {
                logError("dump: \(error.localizedDescription)")
            }
        }
    }
}
