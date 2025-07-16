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
  
 The manager creates and manages async channels for communication between components, coordinates the EventProcessor
 and EventUploader, and handles graceful shutdown. It also manages flush policies and ensures proper sequencing of operations.
 */
final class EventManager {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let eventProcessor: EventProcessor
    private let eventUploader: EventUploader
    private let flushEvent = ProcessingEvent(type: .flush)
    
    /* Centralized channel management */
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    
    /* Flag to prevent multiple shutdown calls and coordinate cleanup */
    private var isShuttingDown = false
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        
        // Create channels centrally for coordinated communication
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        
        // Pass channels to respective classes for decoupled communication
        self.eventProcessor = EventProcessor(analytics: analytics, writeChannel: self.writeChannel, uploadChannel: self.uploadChannel)
        self.eventUploader = EventUploader(analytics: analytics, uploadChannel: self.uploadChannel)
        
        self.start()
    }
}

// MARK: - Operations
extension EventManager {
    
    private func start() {
        self.flushPolicyFacade.startSchedule()
        self.eventProcessor.start()
        self.eventUploader.start()
    }
    
    func put(_ event: Event) {
        self.eventProcessor.put(event)
    }
    
    func flush() {
        LoggerAnalytics.info(log: "Flush triggered...")
        self.eventProcessor.flush()
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
        
        // Close upload channel first to signal EventUploader to stop receiving
        if !self.uploadChannel.isClosed {
            self.uploadChannel.close()
        }
        
        // Now stop uploader - it will complete any ongoing uploads and exit the receive loop
        self.eventUploader.stop()
        
        // Close write channel to signal EventProcessor to stop receiving
        if !self.writeChannel.isClosed {
            self.writeChannel.close()
        }
        
        // Stop processor last to allow final events to be processed
        self.eventProcessor.stop()
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
