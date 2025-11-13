//
//  MessageModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 13/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("MessageModule Tests")
struct MessageModuleTests {
    
    // MARK: - Track Event Tests
    @Test("given parameters to create a track event, when created, then verifies event properties")
    func testTrackEvent() {
        testTrackEvent(name: "Sample Event")
    }
    
    @Test("given parameters to create a track event with properties, when created, then verifies event with properties")
    func testTrackEventProperties() {
        testTrackEvent(name: "Sample Event", properties: ["property": "value"])
    }
    
    @Test("given parameters to create a track event with options, when created, then verifies event with options")
    func testTrackEventOptions() {
        testTrackEvent(name: "Sample Event", options: sampleOptions)
    }
    
    @Test("given parameters to create a track event with properties and options, when created, then verifies event with all data")
    func testTrackEventPropertiesOptions() {
        testTrackEvent(name: "Sample Event", properties: ["property": "value"], options: sampleOptions)
    }
    
    @Test("given fully loaded custom context option for track event, when created, then verifies custom context")
    func testTrackEventCustomContext() {
        testTrackEvent(name: "Sample Event", options: complexOptions)
    }
    
    // MARK: - Screen Event Tests
    @Test("given parameters to create a screen event, when created, then verifies screen event properties")
    func testScreenEvent() {
        testScreenEvent(name: "Sample Screen Event")
    }
    
    @Test("given parameters to create a screen event with properties, when created, then verifies screen event with properties")
    func testScreenEventProperties() {
        testScreenEvent(name: "Sample Screen Event", properties: ["property": "value"])
    }
    
    @Test("given parameters to create a screen event with options, when created, then verifies screen event with options")
    func testScreenEventOptions() {
        testScreenEvent(name: "Sample Screen Event", options: sampleOptions)
    }
    
    @Test("given parameters to create a screen event with properties and options, when created, then verifies screen event with all data")
    func testScreenEventPropertiesOptions() {
        testScreenEvent(name: "Sample Screen Event", properties: ["property": "value"], options: sampleOptions)
    }
    
    @Test("given fully loaded custom context option for screen event, when created, then verifies custom context")
    func testScreenEventCustomContext() {
        testScreenEvent(name: "Sample Screen Event", options: complexOptions)
    }
    
    // MARK: - Group Event Tests
    
    @Test("given parameters to create a group event, when created, then verifies group event properties")
    func testGroupEvent() {
        testGroupEvent(groupId: "Sample_Group_Id")
    }
    
    @Test("given parameters to create a group event with traits, when created, then verifies group event with traits")
    func testGroupEventTraits() {
        testGroupEvent(groupId: "Sample_Group_Id", traits: ["property": "value"])
    }
    
    @Test("given parameters to create a group event with options, when created, then verifies group event with options")
    func testGroupEventOptions() {
        testGroupEvent(groupId: "Sample_Group_Id", options: sampleOptions)
    }
    
    @Test("given parameters to create a group event with traits and options, when created, then verifies group event with all data")
    func testGroupEventPropertiesOptions() {
        testGroupEvent(groupId: "Sample_Group_Id", traits: ["property": "value"], options: sampleOptions)
    }
    
    @Test("given fully loaded custom context option for group event, when created, then verifies custom context")
    func testGroupEventCustomContext() {
        testGroupEvent(groupId: "Sample_Group_Id", options: complexOptions)
    }
    
    // MARK: - Identify Event Tests
    
    @Test("given a simple identify event, when created, then verifies identify event parameters")
    func testSimpleIdentifyEvent() {
        testIdentifyEvent()
    }
    
    @Test("given parameters to create identify event with options, when created, then verifies identify event parameters")
    func testIdentifyEventOption() {
        testIdentifyEvent(options: complexOptions)
    }
    
    // MARK: - Alias Event Tests
    
    @Test("given a simple alias event, when created, then verifies alias event parameters")
    func testSimpleAliasEvent() {
        testAliasEvent()
    }
    
    @Test("given parameters to create a alias event with options, when created, then verifies alias event parameters")
    func testAliasEventOptions() {
        testAliasEvent(options: complexOptions)
    }
    
    @Test("given parameters to create a alias event with previous id, when created, then verifies alias event parameters")
    func testAliasEventPreviousId() {
        testAliasEvent(previousId: "my_previous_id")
    }
    
    @Test("given parameters to create a alias event with previous id and options, when created, then verifies alias event parameters")
    func testAliasEventPreviousIdOptions() {
        testAliasEvent(previousId: "my_previous_id", options: complexOptions)
    }
}

// MARK: - Helper Methods

extension MessageModuleTests {
    
    /// Generic helper to create and validate any event
    @discardableResult
    private func createAndValidateEvent<T: Event>(
        _ event: T,
        expectedType: EventType,
        hasOptions: Bool = false,
        customValidation: ((T) -> Void)? = nil
    ) -> T {
        var updatedEvent = event
        if let updated = event.updateEventData() as? T {
            updatedEvent = updated
        }
        
        validateCommonEventProperties(updatedEvent, expectedType: expectedType)
        if hasOptions {
            validateEventWithOptions(updatedEvent)
        }
        customValidation?(updatedEvent)
        
        return updatedEvent
    }
    
    // MARK: - Specific Event Helpers
    
    /// Helper to test track events with various configurations
    private func testTrackEvent(name: String, properties: [String: Any]? = nil, options: RudderOption? = nil) {
        createAndValidateEvent(
            TrackEvent(event: name, properties: properties, options: options),
            expectedType: .track,
            hasOptions: options != nil
        ) { event in
            #expect(event.event == name)
            if properties != nil {
                #expect(event.properties != nil)
            } else {
                #expect(event.properties == nil)
            }
        }
    }
    
    /// Helper to test screen events with various configurations
    private func testScreenEvent(name: String, properties: [String: Any]? = nil, options: RudderOption? = nil) {
        createAndValidateEvent(
            ScreenEvent(screenName: name, properties: properties, options: options),
            expectedType: .screen,
            hasOptions: options != nil
        ) { event in
            #expect(event.event == name)
            #expect(event.properties != nil) // Screen events always have properties
        }
    }
    
    /// Helper to test group events with various configurations
    private func testGroupEvent(groupId: String, traits: [String: Any]? = nil, options: RudderOption? = nil) {
        createAndValidateEvent(
            GroupEvent(groupId: groupId, traits: traits, options: options),
            expectedType: .group,
            hasOptions: options != nil
        ) { event in
            #expect(event.groupId == groupId)
            if let traits {
                #expect(event.traits != nil)
                #expect(event.traits?.dictionary?.count == traits.count)
            } else {
                #expect(event.traits == nil)
            }
        }
    }
    
    /// Helper to test identify events with various configurations
    private func testIdentifyEvent(options: RudderOption? = nil) {
        createAndValidateEvent(
            IdentifyEvent(options: options),
            expectedType: .identify,
            hasOptions: options != nil
        ) { event in
            #expect(event.options != nil)
        }
    }
    
    /// Helper to test alias events with various configurations
    private func testAliasEvent(previousId: String = .empty, options: RudderOption? = nil) {
        createAndValidateEvent(
            AliasEvent(previousId: previousId, options: options),
            expectedType: .alias,
            hasOptions: options != nil
        ) { event in
            previousId.isEmpty ? #expect(event.previousId.isEmpty) : #expect(!event.previousId.isEmpty)
            #expect(event.options != nil)
        }
    }
    
    /// Creates a sample options object
    private var sampleOptions: RudderOption {
        RudderOption(
            integrations: ["SampleIntegration": false],
            customContext: ["customContext": ["userContext": "content"]]
        )
    }
    
    /// Creates a complex options object for custom context testing
    private var complexOptions: RudderOption {
        RudderOption(
            integrations: ["SDK": true, "Facebook": false],
            customContext: [
                "Key_1": ["Key1": "Value1"],
                "Key_2": ["value1", "value2"],
                "Key_3": "Value3",
                "Key_4": 1234,
                "Key_5": 5678.9,
                "Key_6": true
            ]
        )
    }
    
    /// Common validation for all event types
    private func validateCommonEventProperties<T: Event>(_ event: T, expectedType: EventType) {
        #expect(event.type == expectedType)
        #expect(!event.messageId.isEmpty)
        #expect(!event.originalTimestamp.isEmpty)
        #expect(event.channel == Constants.payload.channel)
        #expect(event.integrations != nil)
        #expect(!(event.sentAt?.isEmpty ?? true))
    }
    
    /// Validates context and integrations for events with options
    private func validateEventWithOptions<T: Event>(_ event: T) {
        #expect(!(event.integrations?.isEmpty ?? true))
        #expect(!(event.context?.isEmpty ?? true))
    }
}
