//
//  MockCustomIntegrationPlugin.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 16/10/25.
//

import Foundation
@testable import RudderStackAnalytics

class MockCustomIntegrationPlugin: IntegrationPlugin {
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
        
        if let error = createThrowsError {
            throw error
        }
        
        // Simulate successful creation
        // hard coded config for custom integration
        destinationInstance = MockDestination(config: ["apiKey": "MyKey"])
    }
    
    // update is overriden (for testing) but should not be called for custom integration
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
        identifyEventReceived = nil
        trackEventReceived = nil
        screenEventReceived = nil
        groupEventReceived = nil
        aliasEventReceived = nil
    }
}
