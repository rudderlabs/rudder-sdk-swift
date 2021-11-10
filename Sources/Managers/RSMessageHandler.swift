//
//  RSMessageHandler.swift
//  Rudder
//
//  Created by Pallab Maiti on 27/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSMessageHandler {
    let factoryDumpManager = RSFactoryDumpManager()
    
    func dumpMessage(_ message: RSMessage) {
        if message.type == .identify {
            if let options = message.option, let externalIds = options.externalIds {
                RSClient.shared.eventManager.cachedContext?.updateExternalIds(externalIds)
            }
            message.context = RSClient.shared.eventManager.cachedContext
        }
        guard RSClient.shared.eventManager.isSDKEnabled == true else {
            return
        }
        if message.integrations?.isEmpty == true, let options = RSClient.shared.eventManager.options, let integrations = options.integrations, !integrations.isEmpty {
            message.integrations = integrations            
        }
        message.isAll = true
        factoryDumpManager.makeFactoryDump(message)
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
    }
}
