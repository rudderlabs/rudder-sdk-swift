//
//  MockIntegrationPlugin.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 13/10/25.
//

import Foundation
@testable import RudderStackAnalytics

/**
 This is a sample standard integration plugin used for testing.
 */
class MockStandardIntegrationPlugin: IntegrationPlugin, StandardIntegration {
    var pluginType: PluginType = .terminal
    var analytics: Analytics?
    var key: String
    
    // Mock destination instance
    private var destinationInstance: Any?
    
    // Track method calls for testing
    var createCalled = false
    var updateCalled = false
    var flushCalled = false
    var resetCalled = false
    var getDestinationInstanceCalled = false
    
    // Track method parameters
    var lastDestinationConfig: [String: Any]?
    var createThrowsError: Error?
    var updateThrowsError: Error?

    // Invoked at the start of create — lets tests simulate events arriving while creation is in flight
    var onCreate: (() -> Void)?

    // Ordered names of all track events delivered to this destination
    var receivedTrackEventNames: [String] = []
    
    // Event tracking
    var identifyEventReceived: IdentifyEvent?
    var trackEventReceived: TrackEvent?
    var screenEventReceived: ScreenEvent?
    var groupEventReceived: GroupEvent?
    var aliasEventReceived: AliasEvent?
    
    init(key: String) {
        self.key = key
    }
    
    func getDestinationInstance() -> Any? {
        getDestinationInstanceCalled = true
        return destinationInstance
    }
    
    func create(destinationConfig: [String: Any]) throws {
        createCalled = true
        lastDestinationConfig = destinationConfig
        onCreate?()

        if let error = createThrowsError {
            throw error
        }
        
        // Simulate successful creation
        destinationInstance = MockDestination(config: destinationConfig)
    }
    
    func update(destinationConfig: [String: Any]) throws {
        updateCalled = true
        lastDestinationConfig = destinationConfig
        
        if let error = updateThrowsError {
            throw error
        }
    }
    
    func flush() {
        flushCalled = true
    }
    
    func reset() {
        resetCalled = true
        destinationInstance = nil
    }
    
    // EventPlugin methods
    func identify(payload: IdentifyEvent) {
        identifyEventReceived = payload
    }
    
    func track(payload: TrackEvent) {
        trackEventReceived = payload
        receivedTrackEventNames.append(payload.event)
    }
    
    func screen(payload: ScreenEvent) {
        screenEventReceived = payload
    }
    
    func group(payload: GroupEvent) {
        groupEventReceived = payload
    }
    
    func alias(payload: AliasEvent) {
        aliasEventReceived = payload
    }
    
    // Helper methods for testing
    func setDestinationInstance(_ instance: Any?) {
        destinationInstance = instance
    }
    
    func resetCallFlags() {
        createCalled = false
        updateCalled = false
        flushCalled = false
        resetCalled = false
        getDestinationInstanceCalled = false
        lastDestinationConfig = nil
        onCreate = nil
        receivedTrackEventNames = []
        identifyEventReceived = nil
        trackEventReceived = nil
        screenEventReceived = nil
        groupEventReceived = nil
        aliasEventReceived = nil
    }
}

// Error types for testing
enum MockIntegrationError: Error {
    case createFailed
    case updateFailed
    case configurationMissing
    case destinationDisabled
}
