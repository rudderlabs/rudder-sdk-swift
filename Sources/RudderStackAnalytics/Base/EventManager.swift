//
//  EventManager.swift
//  Analytics
//
//  Created by Satheesh Kannan on 08/10/24.
//

import Foundation
// MARK: - EventManager
/**
 EventManager is the central coordinator for the analytics event system.
 It orchestrates the flow of events from creation through processing to uploading.
*/
final class EventManager {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let httpClient: HttpClient
    private let flushEvent = ProcessingEvent(type: .flush)
    
    /* Async channel management */
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    
    /* Task management */
    private var writeEventTask: Task<Void, Never>?
    private var uploadEventTask: Task<Void, Never>?
    
    /* Flag to prevent multiple shutdown calls and coordinate cleanup */
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
            do {
                let processingEvent = ProcessingEvent(type: .message, event: event)
                try self.writeChannel.send(processingEvent)
            } catch {
                LoggerAnalytics.error(log: "Failed to send event to writeChannel", error: error)
            }
        }
    }
    
    func flush() {
        LoggerAnalytics.info(log: "Flush triggered...")
        Task {
            do {
                try self.writeChannel.send(self.flushEvent)
            } catch {
                LoggerAnalytics.error(log: "Failed to send flush signal to writeChannel", error: error)
            }
        }
    }
    
    /**
     * Gracefully stops the event management system.
     * Ensures proper shutdown sequence: stops flush policies, closes channels,
     * and allows ongoing operations to complete before full shutdown.
     * This method is idempotent - multiple calls are safe.
     */
    func stop() {
        // Guard against multiple shutdown calls
        guard !isShuttingDown else { return }
        isShuttingDown = true
        
        // Cancel flush policy first to prevent new uploads from being triggered
        self.flushPolicyFacade.cancelSchedule()
        
        // Close upload channel first to signal uploader to stop receiving
        if !self.uploadChannel.isClosed {
            self.uploadChannel.close()
        }
        
        // Wait for upload task to complete naturally
        if let task = self.uploadEventTask {
            task.waitForCompletion()
        }
        
        // Close write channel to signal processor to stop receiving
        if !self.writeChannel.isClosed {
            self.writeChannel.close()
        }
        
        // Wait for write task to complete any remaining events
        if let task = self.writeEventTask {
            task.waitForCompletion()
        }
    }
    
    // MARK: - Event Processing
    private func write() {
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
                
                // Process regular events (not flush signals)
                if !isFlushSignal {
                    if let json = event.event?.jsonString {
                        LoggerAnalytics.debug(log: "Processing event: \(json)")
                        await self.storage.write(event: json)
                        self.flushPolicyFacade.updateCount()
                    }
                }
                
                // Check if we should flush (either explicit flush or policy-triggered)
                if isFlushSignal || self.flushPolicyFacade.shouldFlush() {
                    do {
                        self.flushPolicyFacade.resetCount()
                        await self.storage.rollover()
                        
                        // Only send upload signal if analytics is active
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
    
    // MARK: - Event Uploading
    private func upload() {
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
                
                // Read all available batched events from storage
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    // Check shutdown conditions before processing each item
                    if self.analytics.isAnalyticsShutdown || self.isShuttingDown { break }
                    
                    LoggerAnalytics.debug(log: "Upload started: \(item.reference)")
                    do {
                        // Process the batch by replacing timestamp placeholder with current time
                        let processed = item.batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
                        LoggerAnalytics.debug(log: "Uploading (processed): \(processed)")
                        
                        // Send the batch to the data plane
                        let responseData = try await self.httpClient.postBatchEvents(processed)
                        LoggerAnalytics.debug(log: "Upload response: \(responseData.jsonString ?? "No response")")
                        
                        // Remove successfully uploaded batch from storage
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
/**
 * ProcessingEvent represents an event in the processing pipeline.
 * It can be either a regular message event or a flush signal.
 */
class ProcessingEvent {
    var type: ProcessingEventType
    var event: Event?
    
    init(type: ProcessingEventType, event: Event? = nil) {
        self.type = type
        self.event = event
    }
}

// MARK: - ProcessingEventType
/**
 * Enum representing the different types of processing events.
 */
enum ProcessingEventType {
    case message
    case flush
}
