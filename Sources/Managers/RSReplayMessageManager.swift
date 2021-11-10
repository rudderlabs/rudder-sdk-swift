//
//  RSReplayMessageManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 25/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSReplayMessageManager {
    let factoryDumpManager = RSFactoryDumpManager()
    
    func replayMessageQueue() {
        logDebug("replaying old messages with factory")
        for message in RSClient.shared.eventManager.eventReplayMessageList {
            factoryDumpManager.makeFactoryDump(message)
        }
        RSClient.shared.eventManager.eventReplayMessageList.removeAll()
    }
}
