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
    private let eventProcessor: EventProcessor
    private let eventUploader: EventUploader
    private let flushEvent = ProcessingEvent(type: .flush)
    
    // Centralized channel management
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    
    private var isShuttingDown = false
    
    init(analytics: Analytics) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        
        // Create channels centrally
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        
        // Pass channels to respective classes
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
class ProcessingEvent {
    var type: ProcessingEventType
    var event: Event?
    
    init(type: ProcessingEventType, event: Event? = nil) {
        self.type = type
        self.event = event
    }
}

// MARK: - ProcessingEventType
enum ProcessingEventType {
    case message
    case flush
}
