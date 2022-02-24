//
//  RSProcessorManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 23/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSProcessorManager {
    
    // swiftlint:disable cyclomatic_complexity
    func initiateProcessor() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            logDebug("processor started")
            var errorCode: RSErrorCode?
            var sleepCount = 0
            while true {
                guard let databaseManager = RSClient.shared.eventManager.databaseManager, let config = RSClient.shared.eventManager.config else {
                    return
                }
                let recordCount = databaseManager.getDBRecordCount()
                logDebug("DBRecordCount \(recordCount)")
                if recordCount > config.dbCountThreshold {
                    logDebug("Old DBRecordCount \(recordCount - config.dbCountThreshold)")
                    let dbMessage = databaseManager.fetchEvents(recordCount - config.dbCountThreshold)
                    if let messageIds = dbMessage?.messageIds {
                        databaseManager.clearEvents(messageIds)
                    }
                }
                logDebug("Fetching events to flush to sever")
                guard let dbMessage = databaseManager.fetchEvents(config.flushQueueSize) else {
                    return
                }
                if dbMessage.messages.isEmpty == false, sleepCount >= config.sleepTimeOut {
                    let params = RSUtils.getJSON(from: dbMessage)
                    logDebug("Payload: \(params)")
                    logDebug("EventCount: \(dbMessage.messages.count)")
                    if !params.isEmpty {
                        errorCode = self.flushEventsToServer(params: params)
                        if errorCode == nil {
                            logDebug("clearing events from DB")
                            databaseManager.clearEvents(dbMessage.messageIds)
                            sleepCount = 0
                        }
                    }
                }
                logDebug("SleepCount: \(sleepCount)")
                sleepCount += 1
                if errorCode == .WRONG_WRITE_KEY {
                    logError("Wrong WriteKey. Aborting.")
                } else if errorCode == .SERVER_ERROR {
                    logError("Retrying in: \(abs(sleepCount - config.sleepTimeOut))s")
                    usleep(useconds_t(abs(sleepCount - config.sleepTimeOut)))
                } else {
                    usleep(1000000)
                }
            }
        }
    }
    
    func flushEventsToServer(params: String) -> RSErrorCode? {
        var errorCode: RSErrorCode?
        let semaphore = DispatchSemaphore(value: 0)
        RSClient.shared.eventManager.serviceManager.flushEvents(params: params) { result in
            switch result {
            case .success:
                errorCode = nil
            case .failure(let error):
                errorCode = RSErrorCode(rawValue: error.code)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return errorCode
    }
}
