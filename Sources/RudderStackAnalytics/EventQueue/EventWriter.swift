//
//  EventWriter.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 19/08/25.
//

import Foundation

// MARK: - EventWriter
/**
 EventWriter processes events and writes them to storage.
 */
final class EventWriter {
    private let analytics: Analytics
    private let flushPolicyFacade: FlushPolicyFacade
    private let writeChannel: AsyncChannel<ProcessingEvent>
    private let uploadChannel: AsyncChannel<String>
    private let flushEvent = ProcessingEvent(type: .flush)
    private var lastEventAnonymousId: String?
    private var storage: Storage {
        return self.analytics.configuration.storage
    }
    
    init(analytics: Analytics, writeChannel: AsyncChannel<ProcessingEvent>, uploadChannel: AsyncChannel<String>) {
        self.analytics = analytics
        self.flushPolicyFacade = FlushPolicyFacade(analytics: analytics)
        self.writeChannel = writeChannel
        self.uploadChannel = uploadChannel
        self.lastEventAnonymousId = storage.read(key: Constants.storageKeys.lastEventAnonymousId) ?? analytics.anonymousId
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
        LoggerAnalytics.info("Flush triggered...")
        Task {
            do {
                try self.writeChannel.send(self.flushEvent)
            } catch {
                LoggerAnalytics.error(log: "Failed to send flush signal to writeChannel", error: error)
            }
        }
    }
    
    func start() {
        Task { [weak self] in
            guard let self else { return }
            
            for await event in self.writeChannel.receive() {
                let isFlushSignal = event.type == .flush
                
                // Process regular events (not flush signals)
                if !isFlushSignal {
                    await self.updateAnonymousIdAndRolloverIfNeeded(processingEvent: event)

                    if let json = event.event?.jsonString {
                        LoggerAnalytics.debug("Processing event: \(json)")
                        await self.storage.write(event: json)
                        self.flushPolicyFacade.updateCount()
                    }
                }
                
                // Check if we should flush (either explicit flush or policy-triggered)
                if (isFlushSignal || self.flushPolicyFacade.shouldFlush()) && self.analytics.isSourceEnabled {
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
    
    func startSchedule() {
        self.flushPolicyFacade.startSchedule()
    }
    
    func cancelSchedule() {
        self.flushPolicyFacade.cancelSchedule()
    }
    
    func stop() {
        guard !self.writeChannel.isClosed else { return }
        self.writeChannel.close()
    }

    private func updateAnonymousIdAndRolloverIfNeeded(processingEvent: ProcessingEvent) async {
        guard let lastEventAnonymousId, let currentEventAnonymousId = processingEvent.event?.anonymousId,
              currentEventAnonymousId != lastEventAnonymousId else { return }
        
        // Rollover when last and current anonymousId are different
        await self.storage.rollover()
        self.lastEventAnonymousId = currentEventAnonymousId
        self.storage.write(value: self.lastEventAnonymousId, key: Constants.storageKeys.lastEventAnonymousId)
    }
}
