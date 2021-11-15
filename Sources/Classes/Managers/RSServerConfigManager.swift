//
//  RSServerConfigManager.swift
//  Rudder
//
//  Created by Pallab Maiti on 10/08/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RSServerConfigManager {
    
    var serverConfig: RSServerConfig? = RSUserDefaults.getServerConfig()
    var error: NSError?
    
    func fetchServerConfig() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.manageServerConfig()
            if self.serverConfig == nil {
                logDebug("Server config retrieval failed.No config found in storage")
                logError("Failed to fetch server config for writeKey: \(RSClient.shared.eventManager.writeKey ?? "")")
            }
        }
    }
    
    func isServerConfigOutDated() -> Bool {
        let currentTime = RSUtils.getTimeStamp()
        if let lastUpdatedTime = RSUserDefaults.getLastUpdatedTime(), let config = RSClient.shared.eventManager.config {
            logDebug("Last updated config time: \(lastUpdatedTime)")
            logDebug("Current time: \(currentTime)")
            return (currentTime - lastUpdatedTime) > config.configRefreshInterval * 60 * 60 * 1000
        }
        return false
    }
}

extension RSServerConfigManager {
    private func manageServerConfig() {
        var retryCount = 0
        var isCompleted = false
        while !isCompleted && retryCount < 4 {
            if let serverConfig = downloadServerConfig() {
                self.serverConfig = serverConfig
                RSUserDefaults.saveServerConfig(serverConfig)
                RSUserDefaults.updateLastUpdatedTime(RSUtils.getTimeStamp())
                logDebug("server config download successful")
                isCompleted = true
            } else {
                if error?.code == RSErrorCode.WRONG_WRITE_KEY.rawValue {
                    logDebug("Wrong write key")
                    retryCount = 4
                } else {
                    logDebug("Retrying download in \(retryCount) seconds")
                    retryCount += 1
                    sleep(UInt32(retryCount))
                }
            }
        }
        if !isCompleted {
            logDebug("Server config download failed.Using last stored config from storage")
        }
    }
    
    private func downloadServerConfig() -> RSServerConfig? {
        var serverConfig: RSServerConfig?
        let semaphore = DispatchSemaphore(value: 0)
        RSClient.shared.eventManager.serviceManager.downloadServerConfig { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let config):
                serverConfig = config
            case .failure(let error):
                self.error = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        return serverConfig
    }
}
