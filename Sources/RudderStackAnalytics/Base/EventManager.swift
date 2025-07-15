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
    
    private var writeEventTask: Task<Void, Never>?
    private var uploadEventTask: Task<Void, Never>?
    private var isShuttingDown = false
    
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
            try self.writeChannel.send(processingEvent)
        }
    }
    
    func flush() {
        LoggerAnalytics.info(log: "Flush triggered...")
        Task {
            try self.writeChannel.send(self.flushEvent)
        }
    }
    
    func stop() {
        // Guard against multiple shutdown calls
        guard !isShuttingDown else { return }
        isShuttingDown = true
        
        // Cancel flush policy first to prevent new uploads from being triggered
        self.flushPolicyFacade.cancelSchedule()
        
        // Close upload channel first to signal no more uploads should be initiated
        // The current upload task will complete any ongoing upload before terminating
        if !self.uploadChannel.isClosed {
            self.uploadChannel.close()
        }
        
        // Wait for upload task to complete naturally
        // This allows ongoing uploads to finish
        if let task = self.uploadEventTask {
            task.waitForCompletion()
        }
        
        // Close write channel last to allow incoming events to be saved before shutdown
        if !self.writeChannel.isClosed {
            self.writeChannel.close()
        }
        
        // Wait for write task to complete any remaining events
        if let task = self.writeEventTask {
            task.waitForCompletion()
        }
    }
}

// MARK: - Event Processing
extension EventManager {
    func write() {
        self.writeChannel.setTerminationHandler { [weak self] in
            // Only cancel immediately if not shutting down gracefully
            if self?.isShuttingDown != true {
                self?.writeEventTask?.cancel()
            }
            self?.writeEventTask = nil
        }
        
        self.writeEventTask = Task { [weak self] in
            guard let self else { return }
                        
            for await event in self.writeChannel.receive() {
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
                        
                        if self.analytics.isAnalyticsActive {
                            try self.uploadChannel.send(Constants.defaultConfig.uploadSignal)
                        }
                    } catch {
                        LoggerAnalytics.error(log: "Error on upload signal", error: error)
                    }
                }
            }
        }
    }
    
    func upload() {
        
        self.uploadChannel.setTerminationHandler { [weak self] in
            // Only cancel immediately if not shutting down gracefully
            if self?.isShuttingDown != true {
                self?.uploadEventTask?.cancel()
            }
            self?.uploadEventTask = nil
        }
        
        self.uploadEventTask = Task { [weak self] in
            guard let self else { return }
                        
            for await _ in self.uploadChannel.receive() {
                // If shutdown is initiated, don't start new upload cycles
                if self.isShuttingDown { break }
                
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    // Check shutdown conditions
                    if self.analytics.isAnalyticsShutdown || self.isShuttingDown { 
                        break 
                    }
                    
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
