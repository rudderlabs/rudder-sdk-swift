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
        
        // Always capture the event (before any filtering/modification)
        eventLock.lock()
        capturedEvents.append(event)
        eventLock.unlock()
        
        // Handle filtering
        if shouldFilterEvent {
            return nil
        }
        
        // Handle event modification
        if shouldModifyEvent {
            var modifiedEvent = event
            
            // Apply modifications based on event type
            if var trackEvent = modifiedEvent as? TrackEvent {
                var properties = trackEvent.properties?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    properties[key] = value
                }
                trackEvent.properties = CodableCollection(dictionary: properties)
                modifiedEvent = trackEvent
            } else if var screenEvent = modifiedEvent as? ScreenEvent {
                var properties = screenEvent.properties?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    properties[key] = value
                }
                screenEvent.properties = CodableCollection(dictionary: properties)
                modifiedEvent = screenEvent
            } else if var identifyEvent = modifiedEvent as? IdentifyEvent {
                var traits = identifyEvent.traits?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    traits[key] = value
                }
                identifyEvent.traits = CodableCollection(dictionary: traits)
                modifiedEvent = identifyEvent
            } else if var groupEvent = modifiedEvent as? GroupEvent {
                var traits = groupEvent.traits?.dictionary?.rawDictionary ?? [:]
                for (key, value) in eventModifications {
                    traits[key] = value
                }
                groupEvent.traits = CodableCollection(dictionary: traits)
                modifiedEvent = groupEvent
            }
            
            return modifiedEvent
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
