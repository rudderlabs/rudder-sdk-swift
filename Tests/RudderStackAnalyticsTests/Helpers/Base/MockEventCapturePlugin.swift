//
//  MockEventCapturePlugin.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/11/25.
//

import Foundation
@testable import RudderStackAnalytics

// MARK: - MockEventCapturePlugin
final class MockEventCapturePlugin: Plugin {
    var pluginType: PluginType
    weak var analytics: Analytics?
    
    // Tracking properties
    private(set) var setupCalled = false
    private(set) var executeCalled = false
    private(set) var shutdownCalled = false
    private(set) var capturedEvents: [Event] = []
    private let eventLock = NSLock()
    
    // Configuration properties for advanced testing
    var shouldFilterEvent = false
    var shouldModifyEvent = false
    var eventModifications: [String: Any] = [:]
    
    // MARK: - Initialization
    
    init(type: PluginType = .terminal, enableFiltering: Bool = false, enableModification: Bool = false) {
        self.pluginType = type
        self.shouldFilterEvent = enableFiltering
        self.shouldModifyEvent = enableModification
    }
    
    // MARK: - Plugin Protocol Methods
    
    func setup(analytics: Analytics) {
        self.analytics = analytics
        setupCalled = true
    }
    
    func intercept(event: any Event) -> (any Event)? {
        executeCalled = true
        captureEvent(event)
        
        if shouldFilterEvent {
            return nil
        }
        
        if shouldModifyEvent {
            return applyEventModifications(to: event)
        }
        
        return event
    }
    
    func shutdown() {
        shutdownCalled = true
    }
    
    // MARK: - Event Access Methods
    
    var lastProcessedEvent: Event? {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.last
    }
    
    var receivedEvents: [Event] {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents
    }
    
    func getEventsOfType<T: Event>(_ type: T.Type) -> [T] {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.compactMap { $0 as? T }
    }
    
    func clearEvents() {
        eventLock.lock()
        capturedEvents.removeAll()
        eventLock.unlock()
    }
    
    var eventCount: Int {
        eventLock.lock()
        defer { eventLock.unlock() }
        return capturedEvents.count
    }
    
    // MARK: - Configuration Methods
    
    func enableFiltering() {
        shouldFilterEvent = true
    }
    
    func disableFiltering() {
        shouldFilterEvent = false
    }
    
    func enableModification(with modifications: [String: Any] = [:]) {
        shouldModifyEvent = true
        eventModifications = modifications
    }
    
    func disableModification() {
        shouldModifyEvent = false
        eventModifications = [:]
    }
    
    func setEventModifications(_ modifications: [String: Any]) {
        eventModifications = modifications
    }
}

// MARK: - Private Helper Methods
extension MockEventCapturePlugin {
    private func captureEvent(_ event: any Event) {
        eventLock.lock()
        capturedEvents.append(event)
        eventLock.unlock()
    }
    
    private func applyEventModifications(to event: any Event) -> any Event {
        var modifiedEvent = event
        
        if let trackEvent = modifiedEvent as? TrackEvent {
            modifiedEvent = applyPropertiesModifications(to: trackEvent)
        } else if let screenEvent = modifiedEvent as? ScreenEvent {
            modifiedEvent = applyPropertiesModifications(to: screenEvent)
        } else if let identifyEvent = modifiedEvent as? IdentifyEvent {
            modifiedEvent = applyTraitsModifications(to: identifyEvent)
        } else if let groupEvent = modifiedEvent as? GroupEvent {
            modifiedEvent = applyTraitsModifications(to: groupEvent)
        }
        
        return modifiedEvent
    }
    
    private func applyPropertiesModifications(to trackEvent: TrackEvent) -> TrackEvent {
        var event = trackEvent
        var properties = event.properties?.dictionary?.rawDictionary ?? [:]
        for (key, value) in eventModifications {
            properties[key] = value
        }
        event.properties = CodableCollection(dictionary: properties)
        return event
    }
    
    private func applyPropertiesModifications(to screenEvent: ScreenEvent) -> ScreenEvent {
        var event = screenEvent
        var properties = event.properties?.dictionary?.rawDictionary ?? [:]
        for (key, value) in eventModifications {
            properties[key] = value
        }
        event.properties = CodableCollection(dictionary: properties)
        return event
    }
    
    private func applyTraitsModifications(to identifyEvent: IdentifyEvent) -> IdentifyEvent {
        var event = identifyEvent
        var traits = event.traits?.dictionary?.rawDictionary ?? [:]
        for (key, value) in eventModifications {
            traits[key] = value
        }
        event.traits = CodableCollection(dictionary: traits)
        return event
    }
    
    private func applyTraitsModifications(to groupEvent: GroupEvent) -> GroupEvent {
        var event = groupEvent
        var traits = event.traits?.dictionary?.rawDictionary ?? [:]
        for (key, value) in eventModifications {
            traits[key] = value
        }
        event.traits = CodableCollection(dictionary: traits)
        return event
    }
}

// MARK: - WaitForEvents
extension MockEventCapturePlugin {
    // Generic version (wait for specific type)
    @discardableResult
    func waitForEvents<T: Event>(_ type: T.Type, count expectedCount: Int = 1, timeout: TimeInterval? = nil) async -> [T] {
        let start = Date()
        
        while true {
            let events = getEventsOfType(type)
            if events.count >= expectedCount {
                return events
            }
            if let timeout, Date().timeIntervalSince(start) > timeout {
                return events
            }
            await Task.yield()
        }
    }

    // Non-generic version (wait for all events)
    @discardableResult
    func waitForEvents(count expectedCount: Int = 1, timeout: TimeInterval? = nil) async -> [Event] {
        let start = Date()
        
        while true {
            let events = receivedEvents
            if events.count >= expectedCount {
                return events
            }
            if let timeout, Date().timeIntervalSince(start) > timeout {
                return events
            }
            await Task.yield()
        }
    }
}
