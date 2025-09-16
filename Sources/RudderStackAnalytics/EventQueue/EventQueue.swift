//
//  EventQueue.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/25.
//

import Foundation
import Combine

// MARK: - EventQueue
/**
 EventQueue manages the analytics event pipeline.
*/
final class EventQueue {
    private let analytics: Analytics
    private var eventWriter: EventWriter?
    private var eventUploader: EventUploader?
    
    /** Centralized channel management */
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    
    /** To hold Combine subscriptions */
    private var cancellables = Set<AnyCancellable>()
    
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
        self.eventUploader?.start()
        
        self.observeConfigAndUpdateSchedule()
        self.eventWriter?.start()
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
        
        // Clear any Combine subscriptions
        self.cancellables.removeAll()
    }
    
    func observeConfigAndUpdateSchedule() {
        self.analytics.sourceConfigState.state
            .map { (config: SourceConfig) -> Bool in
                config.source.isSourceEnabled
            }
            .removeDuplicates()
            .sink { [weak self] isSourceEnabled in
                
                guard let self else { return }
                
                if isSourceEnabled {
                    self.eventWriter?.startSchedule()
                    // TODO: Uncomment after dynamic update of source config is implemented
                    // self.eventUploader?.start()
                } else {
                    self.eventWriter?.cancelSchedule()
                }
            }
            .store(in: &cancellables)
    }
}
