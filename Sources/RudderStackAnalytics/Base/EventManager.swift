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
     Stops the event management system by canceling flush policies and closing channels.
     */
    func stop() {
        // Cancel flush policy first to prevent new uploads from being triggered
        self.flushPolicyFacade.cancelSchedule()
        
        // Close upload channel first to signal uploader to stop receiving
        if !self.uploadChannel.isClosed {
            self.uploadChannel.close()
        }
        
        // Close write channel to signal processor to stop receiving
        if !self.writeChannel.isClosed {
            self.writeChannel.close()
        }
    }
    
    // MARK: - Event Processing
    private func write() {
        Task { [weak self] in
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
        Task { [weak self] in
            guard let self else { return }
            
            for await _ in self.uploadChannel.receive() {
                // If shutdown is initiated, don't start new upload cycles
                if self.analytics.isAnalyticsShutdown { break }
                
                // Read all available batched events from storage
                let dataItems = await self.storage.read().dataItems
                for item in dataItems {
                    // Check shutdown conditions before processing each item
                    if self.analytics.isAnalyticsShutdown { break }
                    
                    // Read the event batch from storage
                    let batch = self.analytics.storage.eventStorageMode == .memory ? item.batch : (FileManager.contentsOf(file: item.reference) ?? .empty)
                    guard !batch.isEmpty else { 
                        LoggerAnalytics.debug(log: "No batch found for reference: \(item.reference)")
                        
                        // Remove empty batch from storage
                        await self.storage.remove(eventReference: item.reference)
                        continue
                    }

                    LoggerAnalytics.debug(log: "Upload started: \(item.reference)")
                    do {
                        // Process the batch by replacing timestamp placeholder with current time
                        let processed = batch.replacingOccurrences(of: Constants.payload.sentAtPlaceholder, with: Date().iso8601TimeStamp)
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
private class ProcessingEvent {
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
private enum ProcessingEventType {
    case message
    case flush
}
