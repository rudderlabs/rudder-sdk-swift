//
//  EventQueue.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/25.
//

import Foundation

// MARK: - EventQueue
/**
 EventQueue is the central coordinator for the analytics event system.
 It orchestrates the flow of events from creation through processing to uploading.
  
 The manager creates and manages async channels for communication between components, coordinates the EventWriter
 and EventUploader, and handles graceful shutdown. It also manages flush policies and ensures proper sequencing of operations.
 */
final class EventQueue {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let eventWritter: EventWritter
    private let eventUploader: EventUploader
    
    /* Centralized channel management */
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
        
    init(analytics: Analytics) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        
        // Create channels centrally for coordinated communication
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        
        // Pass channels to respective classes for decoupled communication
        self.eventWritter = EventWritter(analytics: analytics, writeChannel: self.writeChannel, uploadChannel: self.uploadChannel)
        self.eventUploader = EventUploader(analytics: analytics, uploadChannel: self.uploadChannel)
        
        self.start()
    }
}

// MARK: - Operations
extension EventQueue {
    
    private func start() {
        self.flushPolicyFacade.startSchedule()
        self.eventWritter.start()
        self.eventUploader.start()
    }
    
    func put(_ event: Event) {
        self.eventWritter.put(event)
    }
    
    func flush() {
        LoggerAnalytics.info(log: "Flush triggered...")
        self.eventWritter.flush()
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
