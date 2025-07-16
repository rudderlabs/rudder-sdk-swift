//
//  EventProcessor.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 16/07/25.
//

import Foundation

// MARK: - EventProcessor
final class EventProcessor {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    private let flushEvent = ProcessingEvent(type: .flush)
    
    private var writeEventTask: Task<Void, Never>?
    private var isShuttingDown = false
    
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics, writeChannel: AsyncChannel<ProcessingEvent>, uploadChannel: AsyncChannel<String>) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.writeChannel = writeChannel
        self.uploadChannel = uploadChannel
    }
    
    func start() {
        self.write()
    }
    
    func put(_ event: Event) {
        Task {
            let processingEvent = ProcessingEvent(type: .message, event: event)
            try self.writeChannel.send(processingEvent)
        }
    }
    
    func flush() {
        Task {
            try self.writeChannel.send(self.flushEvent)
        }
    }
    
    func stop() {
        // Guard against multiple shutdown calls
        guard !isShuttingDown else { return }
        isShuttingDown = true
        
        // Wait for write task to complete any remaining events
        if let task = self.writeEventTask {
            task.waitForCompletion()
        }
    }
    
    private func write() {
        self.writeChannel.setTerminationHandler { [weak self] in
            // Just clean up the task reference when channel terminates
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
}
