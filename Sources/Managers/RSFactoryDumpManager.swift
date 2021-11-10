//
//  RSFactoryDumpManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 08/09/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSFactoryDumpManager {
    func makeFactoryDump(_ message: RSMessage) {
        if RSClient.shared.eventManager.areFactoriesInitialized == true {
            logDebug("dumping message to native sdk factories")
            if message.isAll {
                for integrationOperation in RSClient.shared.eventManager.integrationOperationList {
                    if message.integrations?[integrationOperation.key] == nil || message.integrations?[integrationOperation.key] as? Bool == true {
                        logDebug("dumping for \(integrationOperation.key)")
                        integrationOperation.integration.dump(message)
                    }
                }
                return
            }
            
            for integrationOperation in RSClient.shared.eventManager.integrationOperationList where message.integrations?[integrationOperation.key] as? Bool == true {
                logDebug("dumping for \(integrationOperation.key)")
                integrationOperation.integration.dump(message)
            }
        } else {
            logDebug("factories are not initialized. dumping to replay queue")
            RSClient.shared.eventManager.eventReplayMessageList.append(message)
        }
    }
}
