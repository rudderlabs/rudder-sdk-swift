//
//  ProcessingEvent.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 20/08/25.
//

import Foundation

// MARK: - ProcessingEventType
/**
 Enum representing the different types of processing events.
 */
enum ProcessingEventType {
    case message
    case flush
}

// MARK: - ProcessingEvent
/**
 ProcessingEvent represents an event in the processing pipeline.
 It can be either a regular message event or a flush signal.
 */
class ProcessingEvent {
    var type: ProcessingEventType
    var event: Event?
    
    init(type: ProcessingEventType, event: Event? = nil) {
        self.type = type
        self.event = event
    }
}
