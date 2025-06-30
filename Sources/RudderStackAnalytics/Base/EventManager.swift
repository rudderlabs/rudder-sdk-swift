//
//  EventManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation
// MARK: - EventManager
/**
 A class responsible for managing events and handling their processing, storage, and uploading in the analytics system.
 This class integrates with the analytics client, manages flush policies, and ensures smooth event flow using asynchronous channels.
 */
final class EventManager {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let httpClient: HttpClient
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    private let flushEvent = ProcessingEvent(type: .flush)
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.httpClient = HttpClient(analytics: analytics)
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        self.start()
    }
    
    deinit {
        self.stop()
    }
}

// MARK: - Operations
extension EventManager {
    
    private func start() {
        self.flushPolicyFacade.startSchedule()
        self.write()
        self.upload()
    }
    
    func put(_ event: Event) {
        Task {
            let processingEvent = ProcessingEvent(type: .message, event: event)
            try await self.writeChannel.send(processingEvent)
        }
    }
    
    func flush() {
        LoggerAnalytics.info(log: "Flush triggered...")
        Task {
            try await self.writeChannel.send(self.flushEvent)
        }
    }
    
    func stop() {
        self.flushPolicyFacade.cancelSchedule()
        
        self.writeChannel.close()
        self.uploadChannel.close()
    }
}

// MARK: - Event Processing
extension EventManager {
    func write() {
        Task { [weak self] in
            guard let self else { return }
            
            for await event in self.writeChannel.stream {
                let isFlushSignal = event.type == .flush
                
                if !isFlushSignal {
                    if let json = event.event?.jsonString {
                        LoggerAnalytics.debug(log: "Processing event: \(json)")
                        await self.storage.write(event: json)
                        self.flushPolicyFacade.updateCount()
                    }
                }
                
                if isFlushSignal || self.flushPolicyFacade.shouldFlush() {
                    do {
                        self.flushPolicyFacade.resetCount()
                        await self.storage.rollover()
                        try await self.uploadChannel.send(Constants.defaultConfig.uploadSignal)
                    } catch {
                        LoggerAnalytics.error(log: "Error on upload signal", error: error)
                    }
                }
            }
        }
    }
    
    func upload() {
        Task { [weak self] in
            guard let self else { return }
            
            for await _ in self.uploadChannel.stream {
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    LoggerAnalytics.debug(log: "Upload started: \(item.reference)")
                    
                    do {
                        let processed = item.batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
                        LoggerAnalytics.debug(log: "Uploading (processed): \(processed)")
                        
                        let responseData = try await self.httpClient.postBatchEvents(processed)
                        LoggerAnalytics.debug(log: "Upload response: \(responseData.jsonString ?? "No response")")
                        
                        await self.storage.remove(eventReference: item.reference)
                        LoggerAnalytics.debug(log: "Upload completed: \(item.reference)")
                    } catch {
                        LoggerAnalytics.error(log: "Upload failed: \(item.reference)", error: error)
                    }
                }
            }
        }
    }
}

// MARK: - ProcessingEvent
private class ProcessingEvent {
    var type: ProcessingEventType
    var event: Event?
    
    init(type: ProcessingEventType, event: Event? = nil) {
        self.type = type
        self.event = event
    }
}

// MARK: - ProcessingEventType
private enum ProcessingEventType {
    case message
    case flush
}
