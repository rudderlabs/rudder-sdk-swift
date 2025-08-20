//
//  EventQueue.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/25.
//

import Foundation

// MARK: - EventQueue
/**
 EventQueue manages the analytics event pipeline.
*/
final class EventQueue {
    private let analytics: Analytics
    private var eventWriter: EventWriter?
    private var eventUploader: EventUploader?
    
    /* Centralized channel management */
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
        
    init(analytics: Analytics) {
        self.analytics = analytics
        
        // Create channels centrally for coordinated communication
        self.writeChannel = AsyncChannel()
        self.uploadChannel = AsyncChannel()
        
        // Pass channels to respective classes for decoupled communication
        self.eventWriter = EventWriter(analytics: analytics, writeChannel: self.writeChannel, uploadChannel: self.uploadChannel)
        self.eventUploader = EventUploader(analytics: analytics, uploadChannel: self.uploadChannel)
        
        self.start()
    }
    
    deinit {
        self.eventWriter = nil
        self.eventUploader = nil
    }
}

// MARK: - Operations
extension EventQueue {
    
    private func start() {
        self.eventWriter?.start()
        self.eventUploader?.start()
    }
    
    func put(_ event: Event) {
        self.eventWriter?.put(event)
    }
    
    func flush() {
        self.eventWriter?.flush()
    }
    
    /**
     Stops the event management system by canceling flush policies and closing channels.
     */
    func stop() {
        // Cancel flush policy first to prevent new uploads from being triggered
        self.eventWriter?.cancelSchedule()
        
        // Close upload channel first to signal uploader to stop receiving
        self.eventUploader?.stop()
        
        // Close write channel to signal processor to stop receiving
        self.eventWriter?.stop()
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
