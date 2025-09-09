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
        self.stop()
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
    private func stop() {
        // Cancel flush policy first to prevent new uploads from being triggered
        self.eventWriter?.cancelSchedule()
        
        // Close upload channel first to signal uploader to stop receiving
        self.eventUploader?.stop()
        
        // Close write channel to signal processor to stop receiving
        self.eventWriter?.stop()
    }
}
