//
//  RudderDestination.swift
//  Rudder
//
//  Created by Pallab Maiti on 24/02/22.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

class RudderDestinationPlugin: RSDestinationPlugin {
    var key: String = ""
    
    let type = PluginType.destination
//    let key: String = Constants.integrationName.rawValue
    let controller = RSController()
    var client: RSClient? {
        didSet {
            initialSetup()
        }
    }

    private let uploadsQueue = DispatchQueue(label: "uploadsQueue.rudder.com")
    private var flushTimer: RSQueueTimer?
    
    private var messageHandler: RSMessageHandler?
    private var serviceManager: RSServiceManager?
    
    func initialSetup() {
        guard let client = self.client else { return }
        messageHandler = RSMessageHandler()
        serviceManager = RSServiceManager(client: client)
        flushTimer = RSQueueTimer(interval: TimeInterval(client.config.sleepTimeOut)) {
            self.flushMessage()
        }
    }
        
    // MARK: - Event Handling Methods
    func execute<T: RSMessage>(event: T?) -> T? {
        let result: T? = event
        if let r = result {
            let modified = configureCloudDestinations(event: r)
            queueEvent(event: modified)
        }
        return result
    }
    
    // MARK: - Abstracted Lifecycle Methods
    internal func enterForeground() {
        flushTimer?.resume()
    }
    
    internal func enterBackground() {
        flushTimer?.suspend()
        flushMessage()
    }
    
    // MARK: - Event Parsing Methods
    private func queueEvent<T: RSMessage>(event: T) {
        guard let messageHandler = self.messageHandler else { return }
        messageHandler.write(event)
        flushMessage()
    }
}

// MARK: - Utility methods
extension RudderDestinationPlugin {
    internal func configureCloudDestinations<T: RSMessage>(event: T) -> T {
        guard let integrationSettings = client?.serverConfig else { return event }
        guard let plugins = client?.controller.plugins[.destination]?.plugins as? [RSDestinationPlugin] else { return event }
        guard let customerValues = event.integrations else { return event }
        
        var merged = [String: Bool]()
        
        // compare settings to loaded plugins
        for plugin in plugins {
            var hasSettings = false
            if let destinations = integrationSettings.destinations {
                if let destination = destinations.first(where: { $0.destinationDefinition?.displayName == plugin.key }), destination.enabled {
                    hasSettings = true
                }
            }
            if hasSettings {
                // we have a device mode plugin installed.
                // tell segment not to send it via cloud mode.
                merged[plugin.key] = false
            }
        }
        
        // apply customer values; the customer is always right!
        for (key, value) in customerValues {
            merged[key] = value
        }
        
        var modified = event
        modified.integrations = merged
        
        return modified
    }
}

extension RudderDestinationPlugin {
    
    // swiftlint:disable cyclomatic_complexity
    func flushMessage() {
        uploadsQueue.sync { [weak self] in
            guard let self = self else { return }
            logDebug("processor started")
            var errorCode: RSErrorCode?
            var sleepCount = 0
            while true {
                guard let databaseManager = client?.databaseManager, let config = client?.config else {
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
        serviceManager?.flushEvents(params: params) { result in
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
