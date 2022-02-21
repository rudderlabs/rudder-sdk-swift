//
//  SegmentDestination.swift
//  Segment
//
//  Created by Cody Garvin on 1/5/21.
//

import Foundation

#if os(Linux)
// Whoever is doing swift/linux development over there
// decided that it'd be a good idea to split out a TON
// of stuff into another framework that NO OTHER PLATFORM
// has; I guess to be special.  :man-shrugging:
import FoundationNetworking
#endif

public class SegmentDestination: DestinationPlugin {
//    internal enum Constants: String {
//        case integrationName = "Segment.io"
//        case apiHost = "apiHost"
//        case apiKey = "apiKey"
//    }
    
    public let type = PluginType.destination
//    public let key: String = Constants.integrationName.rawValue
    public let timeline = Timeline()
    public var analytics: Analytics? {
        didSet {
            initialSetup()
        }
    }

//    internal struct UploadTaskInfo {
//        let url: URL
//        let task: URLSessionDataTask
//        // set/used via an extension in iOSLifecycleMonitor.swift
//        typealias CleanupClosure = () -> Void
//        var taskID: Int = 0
//        var cleanup: CleanupClosure? = nil
//    }
    
//    private var httpClient: HTTPClient?
//    private var uploads = [UploadTaskInfo]()
    private let uploadsQueue = DispatchQueue(label: "uploadsQueue.segment.com")
//    private var storage: Storage?
    
//    private var apiKey: String? = nil
//    private var apiHost: String? = nil
    
//    @Atomic private var eventCount: Int = 0
    internal var flushTimer: QueueTimer? = nil
    
    private var messageHandler: RSMessageHandler?
    private var serviceManager: RSServiceManager?
    
    internal func initialSetup() {
        guard let analytics = self.analytics else { return }
        messageHandler = analytics.messageHandler
        serviceManager = RSServiceManager()
        
        
//        storage = analytics.storage
//        httpClient = HTTPClient(analytics: analytics)
        flushTimer = QueueTimer(interval: analytics.config.sleepTimeOut) {
//            self.flush()
            self.flushMessage()
        }
    }
    
    public func update(settings: Settings, type: UpdateType) {
        let segmentInfo = settings.integrationSettings(forKey: self.key)
        apiKey = segmentInfo?[Self.Constants.apiKey.rawValue] as? String
        apiHost = segmentInfo?[Self.Constants.apiHost.rawValue] as? String
        if (apiHost != nil && apiKey != nil), let analytics = self.analytics {
            httpClient = HTTPClient(analytics: analytics, apiKey: apiKey, apiHost: apiHost)
        }
    }
    
    // MARK: - Event Handling Methods
    public func execute<T: Message>(event: T?) -> T? {
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
//        flush()
        flushMessage()
    }
    
    // MARK: - Event Parsing Methods
    private func queueEvent<T: Message>(event: T) {
//        guard let storage = self.storage else { return }
//        guard let analytics = self.analytics else { return }
        guard let messageHandler = self.messageHandler else { return }
        
        // Send Event to File System
//        storage.write(.events, value: event)
        messageHandler.write(event)
//        eventCount += 1
//        if eventCount >= analytics.configuration.values.flushAt {
//            eventCount = 0
//            flush()
            flushMessage()
//        }
    }
    
    /*public func flush() {
        guard let storage = self.storage else { return }
        guard let analytics = self.analytics else { return }
        guard let httpClient = self.httpClient else { return }

        // Read events from file system
        guard let data = storage.read(Storage.Constants.events) else { return }
        
        cleanupUploads()
        
        analytics.log(message: "Uploads in-progress: \(pendingUploads)")
        
        if pendingUploads == 0 {
            for url in data {
                analytics.log(message: "Processing Batch:\n\(url.lastPathComponent)")
                
                let uploadTask = httpClient.startBatchUpload(writeKey: analytics.configuration.values.writeKey, batch: url) { (result) in
                    switch result {
                        case .success(_):
                            storage.remove(file: url)
                        default:
                            analytics.logFlush()
                    }
                    
                    analytics.log(message: "Processed: \(url.lastPathComponent)")
                }
                // we have a legit upload in progress now, so add it to our list.
                if let upload = uploadTask {
                    add(uploadTask: UploadTaskInfo(url: url, task: upload))
                }
            }
        } else {
            analytics.log(message: "Skipping processing; Uploads in progress.")
        }
    }*/
}

// MARK: - Utility methods
extension SegmentDestination {
    internal func configureCloudDestinations<T: Message>(event: T) -> T {
        guard let integrationSettings = analytics?.settings() else { return event }
        guard let plugins = analytics?.timeline.plugins[.destination]?.plugins as? [DestinationPlugin] else { return event }
        guard let customerValues = event.integrations?.dictionaryValue else { return event }
        
        var merged = [String: Any]()
        
        // compare settings to loaded plugins
        for plugin in plugins {
            let hasSettings = integrationSettings.hasIntegrationSettings(forPlugin: plugin)
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
        modified.integrations = try? JSON(merged)
        
        return modified
    }
}

// MARK: - Upload management
/*
extension SegmentDestination {
    internal func cleanupUploads() {
        // lets go through and get rid of any tasks that aren't running.
        // either they were suspended because a background task took too
        // long, or the os orphaned it due to device constraints (like a watch).
        uploadsQueue.sync {
            let before = uploads.count
            var newPending = uploads
            newPending.removeAll { uploadInfo in
                let shouldRemove = uploadInfo.task.state != .running
                if shouldRemove, let cleanup = uploadInfo.cleanup {
                    cleanup()
                }
                return shouldRemove
            }
            uploads = newPending
            let after = uploads.count
            analytics?.log(message: "Cleaned up \(before - after) non-running uploads.")
        }
    }
    
    internal var pendingUploads: Int {
        var uploadsCount = 0
        uploadsQueue.sync {
            uploadsCount = uploads.count
        }
        return uploadsCount
    }
    
    internal func add(uploadTask: UploadTaskInfo) {
        uploadsQueue.sync {
            uploads.append(uploadTask)
        }
    }
}
*/
extension SegmentDestination {
    
    // swiftlint:disable cyclomatic_complexity
    func flushMessage() {
        uploadsQueue.sync { [weak self] in
            guard let self = self else { return }
            logDebug("processor started")
            var errorCode: RSErrorCode?
            var sleepCount = 0
            while true {
                guard let databaseManager = databaseManager, let analytics = self.analytics, let config = analytics.config else {
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
        serviceManager.flushEvents(params: params) { result in
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