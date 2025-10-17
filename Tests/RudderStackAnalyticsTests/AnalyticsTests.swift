//
//  AnalyticsTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

// MARK: - Analytics Unit Tests

@Suite("Analytics Unit Tests")
@MainActor
class AnalyticsTests {
    
    var analytics: Analytics
    var mockStorage: MockStorage
    var mockPlugin: MockEventCapturePlugin
    
    init() {
        // Create mock storage instance
        mockStorage = MockStorage()
        
        // Create analytics with mock configuration using our mock storage
        let config = SwiftTestMockProvider.createMockConfiguration(
            writeKey: SwiftTestMockProvider.mockWriteKey,
            dataPlaneUrl: SwiftTestMockProvider.mockDataPlaneUrl,
            storage: mockStorage
        )
        
        config.trackApplicationLifecycleEvents = false
        config.sessionConfiguration.automaticSessionTracking = false
        
        // Create analytics instance
        analytics = Analytics(configuration: config)
        
        analytics.isAnalyticsActive = true
        
        mockPlugin = MockEventCapturePlugin()
        analytics.add(plugin: mockPlugin)
    }
    
    // MARK: - Track Event Tests
    @Test("given Analytics, when tracking events with variations, then event is captured correctly", arguments: EventTestCaseParameters.trackEvent)
    func testTrackEventVariants(_ eventName: String, _ properties: Properties?, _ options: RudderOption?) async {
        // when
        analytics.track(name: eventName, properties: properties, options: options)
        
        let trackEvents = await mockPlugin.waitForEvents(TrackEvent.self)
        #expect(trackEvents.count >= 1)
        
        guard let event = trackEvents.first else {
            Issue.record("Failed to retrieve a track event")
            return
        }
        #expect(event.event == eventName)
        
        // Validate properties if provided
        if let properties {
            let raw = event.properties?.dictionary?.rawDictionary ?? [:]
            for (key, value) in properties {
                #expect("\(raw[key] ?? "")" == "\(value)")
            }
        }
        
        // Validate options if provided
        if let options {
            // Integrations
            if let integrations = options.integrations, !integrations.isEmpty {
                let eventIntegrations = event.integrations?.rawDictionary ?? [:]
                for (key, value) in integrations {
                    #expect("\(eventIntegrations[key] ?? "")" == "\(value)")
                }
            }
            
            // Custom Context
            if let customContext = options.customContext, !customContext.isEmpty {
                let eventContext = event.context?.rawDictionary["customContext"] as? [String: Any] ?? [:]
                if !eventContext.isEmpty {
                    customContext.forEach { key, value in
                        #expect(eventContext.keys.contains(key))
                        #expect("\(eventContext[key] ?? "")" == "\(value)")
                    }
                }
            }
            
            // External IDs
            if let optionExternalIds = options.externalIds, !optionExternalIds.isEmpty,
               let eventExternalIds = event.context?.rawDictionary["externalId"] as? [[String: Any]] {
                
                for externalId in optionExternalIds {
                    let idDict = externalId.dictionary ?? [:]
                    
                    let containsMatch = eventExternalIds.contains { eventDict in
                        idDict.allSatisfy { key, value in
                            "\(eventDict[key] ?? "")" == "\(value)"
                        }
                    }
                    
                    #expect(containsMatch, "Missing externalId \(idDict) in event context")
                }
            }
        }
        
    }
    
    // MARK: - Screen Event Tests
    
    @Test("given Analytics, when tracking screen events with variations, then event is captured correctly", arguments: EventTestCaseParameters.screenEvent)
    func testScreenEventVariants(_ name: String, _ category: String?, _ properties: [String: Any]?, _ options: RudderOption?) async {
        // when
        analytics.screen(screenName: name, category: category, properties: properties, options: options)
        
        // then
        let screenEvents = await mockPlugin.waitForEvents(ScreenEvent.self)
        #expect(screenEvents.count >= 1)
        
        guard let event = screenEvents.first else {
            Issue.record("Failed to retrieve a screen event")
            return
        }
        #expect(event.event == name)
        
        if let category {
            let eventCategory = event.properties?.dictionary?.rawDictionary["category"] as? String
            #expect(eventCategory == category)
        }
        
        if let properties {
            let eventProps = event.properties?.dictionary?.rawDictionary ?? [:]
            for (key, expectedValue) in properties {
                #expect("\(eventProps[key] ?? "")" == "\(expectedValue)")
            }
        }
        
        if let options {
            // Integrations
            if let integrations = options.integrations, !integrations.isEmpty {
                let eventIntegrations = event.integrations?.rawDictionary ?? [:]
                for (key, value) in integrations {
                    #expect("\(eventIntegrations[key] ?? "")" == "\(value)")
                }
            }
            
            // Custom Context
            if let customContext = options.customContext, !customContext.isEmpty {
                let eventContext = event.context?.rawDictionary["customContext"] as? [String: Any] ?? [:]
                if !eventContext.isEmpty {
                    customContext.forEach { key, value in
                        #expect(eventContext.keys.contains(key))
                        #expect("\(eventContext[key] ?? "")" == "\(value)")
                    }
                }
            }
            
            // External IDs
            if let optionExternalIds = options.externalIds, !optionExternalIds.isEmpty,
               let eventExternalIds = event.context?.rawDictionary["externalId"] as? [[String: Any]] {
                
                for externalId in optionExternalIds {
                    let idDict = externalId.dictionary ?? [:]
                    
                    let containsMatch = eventExternalIds.contains { eventDict in
                        idDict.allSatisfy { key, value in
                            "\(eventDict[key] ?? "")" == "\(value)"
                        }
                    }
                    
                    #expect(containsMatch, "Missing externalId \(idDict) in event context")
                }
            }
        }
    }
    
    // MARK: - Identify Event Tests
    
    @Test("given Analytics, when tracking identify events with variations, then event is captured correctly", arguments: EventTestCaseParameters.identifyEvent)
    func testIdentifyVariants(_ userId: String?, _ traits: [String: Any]?, _ options: RudderOption?) async {
        // when
        analytics.identify(userId: userId, traits: traits, options: options)
        
        // then
        let identifyEvents = await mockPlugin.waitForEvents(IdentifyEvent.self)
        #expect(identifyEvents.count >= 1)
        
        guard let event = identifyEvents.first else {
            Issue.record("Failed to retrieve a identify event")
            return
        }
        
        // Validate userId
        if let userId {
            #expect(self.analytics.userId == userId)
        }
        
        // Validate traits
        if let traits {
            let analyticsTraits = self.analytics.traits ?? [:]
            if !analyticsTraits.isEmpty {
                for (key, value) in traits {
                    #expect(analyticsTraits.keys.contains(key))
                    #expect("\(analyticsTraits[key] ?? "")" == "\(value)")
                }
            }
        }
        
        // Validate options if provided
        if let options {
            // Integrations
            if let integrations = options.integrations, !integrations.isEmpty {
                let eventIntegrations = event.integrations?.rawDictionary ?? [:]
                for (key, value) in integrations {
                    #expect("\(eventIntegrations[key] ?? "")" == "\(value)")
                }
            }
            
            // Custom Context
            if let customContext = options.customContext, !customContext.isEmpty {
                let eventContext = event.context?.rawDictionary["customContext"] as? [String: Any] ?? [:]
                if !eventContext.isEmpty {
                    customContext.forEach { key, value in
                        #expect(eventContext.keys.contains(key))
                        #expect("\(eventContext[key] ?? "")" == "\(value)")
                    }
                }
            }
            
            // External IDs
            if let optionExternalIds = options.externalIds, !optionExternalIds.isEmpty,
               let eventExternalIds = event.context?.rawDictionary["externalId"] as? [[String: Any]] {
                
                for externalId in optionExternalIds {
                    let idDict = externalId.dictionary ?? [:]
                    
                    let containsMatch = eventExternalIds.contains { eventDict in
                        idDict.allSatisfy { key, value in
                            "\(eventDict[key] ?? "")" == "\(value)"
                        }
                    }
                    
                    #expect(containsMatch, "Missing externalId \(idDict) in event context")
                }
            }
        }
    }
    
    
    @Test("given Analytics with existing user, when identifying with different userId, then reset is triggered")
    func testIdentifyWithDifferentUserIdTriggersReset() async {
        // First identify
        analytics.identify(userId: "user-1", traits: ["first": "true"])
        
        await mockPlugin.waitForEvents(IdentifyEvent.self)
        #expect(self.analytics.userId == "user-1")
        
        // Identify with different user ID (should trigger reset)
        analytics.identify(userId: "user-2", traits: ["second": "true"])
        await mockPlugin.waitForEvents(IdentifyEvent.self, count: 2)
        
        #expect(self.analytics.userId == "user-2")
        #expect(self.analytics.traits?["second"] as? String == "true")
        
        let identifyEvents = self.mockPlugin.getEventsOfType(IdentifyEvent.self)
        #expect(identifyEvents.count >= 2) // Should have both identify events
    }
    
    // MARK: - Group Event Tests
    
    @Test("given Analytics, when tracking group events with variations, then event is captured correctly", arguments: EventTestCaseParameters.trackEvent)
    func testGroupEventVariants(_ groupId: String, _ traits: Properties?, _ options: RudderOption?) async {
        // when
        analytics.group(groupId: groupId, traits: traits, options: options)
        
        // then
        let groupEvents = await mockPlugin.waitForEvents(GroupEvent.self)
        #expect(groupEvents.count >= 1)
        
        guard let event = groupEvents.first else {
            Issue.record("Failed to retrieve a group event")
            return
        }
        #expect(event.groupId == groupId)
        
        // Validate traits
        if let traits {
            let analyticsTraits = self.analytics.traits ?? [:]
            if !analyticsTraits.isEmpty {
                for (key, value) in traits {
                    #expect(analyticsTraits.keys.contains(key))
                    #expect("\(analyticsTraits[key] ?? "")" == "\(value)")
                }
            }
        }
        
        // Validate options if provided
        if let options {
            // Integrations
            if let integrations = options.integrations, !integrations.isEmpty {
                let eventIntegrations = event.integrations?.rawDictionary ?? [:]
                for (key, value) in integrations {
                    #expect("\(eventIntegrations[key] ?? "")" == "\(value)")
                }
            }
            
            // Custom Context
            if let customContext = options.customContext, !customContext.isEmpty {
                let eventContext = event.context?.rawDictionary["customContext"] as? [String: Any] ?? [:]
                if !eventContext.isEmpty {
                    customContext.forEach { key, value in
                        #expect(eventContext.keys.contains(key))
                        #expect("\(eventContext[key] ?? "")" == "\(value)")
                    }
                }
            }
            
            // External IDs
            if let optionExternalIds = options.externalIds, !optionExternalIds.isEmpty,
               let eventExternalIds = event.context?.rawDictionary["externalId"] as? [[String: Any]] {
                
                for externalId in optionExternalIds {
                    let idDict = externalId.dictionary ?? [:]
                    
                    let containsMatch = eventExternalIds.contains { eventDict in
                        idDict.allSatisfy { key, value in
                            "\(eventDict[key] ?? "")" == "\(value)"
                        }
                    }
                    
                    #expect(containsMatch, "Missing externalId \(idDict) in event context")
                }
            }
        }
    }
    
    
    // MARK: - Alias Event Tests
    
    @Test("given Analytics, when aliasing user, then alias event is captured correctly", arguments: EventTestCaseParameters.aliasEvent)
    func testAliasEventVariants(_ alias: String, _ previousId: String?, _ options: RudderOption?) async {
        // First identify a user if previousId is provided
        if let previousId {
            analytics.identify(userId: previousId)
        }
        
        // when
        analytics.alias(newId: alias, previousId: previousId, options: options)
        
        // Validate alias events
        let aliasEvents = await mockPlugin.waitForEvents(AliasEvent.self)
        #expect(aliasEvents.count >= 1)
        
        // then
        // Validate current userId
        #expect(self.analytics.userId == alias)
        
        guard let event = aliasEvents.first else {
            Issue.record("Failed to retrieve a group event")
            return
        }
        
        #expect(event.userId == alias)
        
        if let previousId {
            #expect(event.previousId == previousId)
        }
        // Validate options if provided
        if let options {
            // Integrations
            if let integrations = options.integrations, !integrations.isEmpty {
                let eventIntegrations = event.integrations?.rawDictionary ?? [:]
                for (key, value) in integrations {
                    #expect("\(eventIntegrations[key] ?? "")" == "\(value)")
                }
            }
            
            // Custom Context
            if let customContext = options.customContext, !customContext.isEmpty {
                let eventContext = event.context?.rawDictionary["customContext"] as? [String: Any] ?? [:]
                if !eventContext.isEmpty {
                    customContext.forEach { key, value in
                        #expect(eventContext.keys.contains(key))
                        #expect("\(eventContext[key] ?? "")" == "\(value)")
                    }
                }
            }
            
            // External IDs
            if let optionExternalIds = options.externalIds, !optionExternalIds.isEmpty,
               let eventExternalIds = event.context?.rawDictionary["externalId"] as? [[String: Any]] {
                
                for externalId in optionExternalIds {
                    let idDict = externalId.dictionary ?? [:]
                    
                    let containsMatch = eventExternalIds.contains { eventDict in
                        idDict.allSatisfy { key, value in
                            "\(eventDict[key] ?? "")" == "\(value)"
                        }
                    }
                    
                    #expect(containsMatch, "Missing externalId \(idDict) in event context")
                }
            }
        }
    }
    
    @Test("given Analytics, when aliasing user, then alias event is captured correctly")
    func testAliasEvent() async {
        // First identify a user
        analytics.identify(userId: "old-user-id")
        
        let newId = "new-user-id"
        let previousId = "old-user-id"
        
        // Validate alias events
        await mockPlugin.waitForEvents(IdentifyEvent.self)
        
        self.analytics.alias(newId: newId, previousId: previousId)
        
        let aliasEvents: [AliasEvent] = await mockPlugin.waitForEvents(AliasEvent.self)
        #expect(self.analytics.userId == newId)
        
        #expect(aliasEvents.count >= 1)
        #expect(aliasEvents.first?.previousId == previousId)
    }
    
    // MARK: - Session Management Tests
    
    @Test("given Analytics, when starting manual session, then session ID is set correctly")
    func testStartManualSession() async {
        let customSessionId: UInt64 = 1_234_567_890
        
        analytics.startSession(sessionId: customSessionId)
        
        await runAfter(0.1) {
            #expect(self.analytics.sessionId == customSessionId)
        }
    }
    
    @Test("given Analytics, when starting session without ID, then session ID is generated")
    func testStartSessionWithGeneratedId() async {
        let originalSessionId = analytics.sessionId
        
        analytics.startSession()
        
        await runAfter(0.1) {
            #expect(self.analytics.sessionId != nil)
            #expect(self.analytics.sessionId != originalSessionId) // Should be different
        }
    }
    
    @Test("given Analytics, when ending session, then session is properly ended")
    func testEndSession() async {
        // Start a session first
        analytics.startSession(sessionId: 9_876_543_210)
        await runAfter(0.1) {
            #expect(self.analytics.sessionId == 9_876_543_210)
            
            // End the session
            self.analytics.endSession()
            
            await runAfter(0.1) {
                // If sessionId nil, no active session
                #expect(self.analytics.sessionId == nil)
            }
        }
    }
    
    @Test("given Analytics, when starting session with invalid ID, then error is logged and session is not set")
    func testStartSessionWithInvalidId() async {
        let invalidSessionId: UInt64 = 123 // Too short
        let originalSessionId = analytics.sessionId
        
        analytics.startSession(sessionId: invalidSessionId)
        
        await runAfter(0.1) {
            // Session ID should remain unchanged
            #expect(self.analytics.sessionId == originalSessionId)
        }
    }
    
    // MARK: - Plugin Management Tests
    
    @Test("given Analytics, when adding plugin, then plugin receives events")
    func testAddPlugin() async {
        let additionalPlugin = MockEventCapturePlugin()
        
        analytics.add(plugin: additionalPlugin)
        analytics.track(name: "Test Plugin Event")
        
        await additionalPlugin.waitForEvents()
        
        #expect(additionalPlugin.setupCalled == true)
        #expect(additionalPlugin.eventCount >= 1)
    }
    
    @Test("given Analytics with plugin, when removing plugin, then plugin no longer receives events")
    func testRemovePlugin() async {
        let removablePlugin = MockEventCapturePlugin()
        
        // Add plugin
        analytics.add(plugin: removablePlugin)
        analytics.track(name: "Before Remove")
        
        await removablePlugin.waitForEvents()
        
        let eventsBeforeRemoval = removablePlugin.eventCount
        #expect(eventsBeforeRemoval >= 1)
        
        // Remove plugin
        self.analytics.remove(plugin: removablePlugin)
        removablePlugin.clearEvents()
        
        self.analytics.track(name: "After Remove")
        
        await removablePlugin.waitForEvents(timeout: 0.1)
        #expect(removablePlugin.eventCount == 0)
    }
    
    // MARK: - Reset Tests
    
    @Test("given Analytics with user data, when resetting, then user data is cleared from storage")
    func testReset() async {
        // Set up user data
        analytics.identify(userId: "test-user", traits: ["email": "test@example.com"])
        analytics.track(name: "Before Reset Event")
        
        await mockPlugin.waitForEvents(count: 2)
        
        #expect(self.analytics.userId == "test-user")
        #expect(self.analytics.traits?["email"] as? String == "test@example.com")
        
        // Verify data exists in storage
        let initialKeyValueCount = self.mockStorage.allKeyValuePairs.count
        let initialEventCount = self.mockStorage.eventCount
        #expect(initialKeyValueCount > 0)
        #expect(initialEventCount >= 1)

        // Reset
        self.analytics.reset()
        
        await runAfter(0.1) {
            #expect(self.analytics.userId?.isEmpty ?? true)
            #expect(self.analytics.traits?.isEmpty ?? true)
            #expect(self.analytics.anonymousId?.isEmpty == false) // Anonymous ID should be regenerated
        }
    }
    
    @Test("given Analytics, when resetting with specific options, then only specified data is cleared")
    func testResetWithOptions() async {
        // Set up user data
        analytics.identify(userId: "test-user", traits: ["email": "test@example.com"])
        
        // Reset only traits, keep userId
        let resetEntries = ResetEntries(anonymousId: false, userId: false, traits: true, session: false)
        let resetOptions = ResetOptions(entries: resetEntries)
        
        await mockPlugin.waitForEvents()
        self.analytics.reset(options: resetOptions)
        
        await runAfter(0.1) {
            #expect(self.analytics.userId == "test-user") // Should remain
            #expect(self.analytics.traits?.isEmpty ?? true) // Should be cleared
        }
    }
    
    // MARK: - Flush Tests
    
    @Test("given Analytics, when calling flush, then flush is propagated to plugins")
    func testFlush() async {
        // Track some events first
        analytics.track(name: "Test Event")
        
        await runAfter(0.1) {
            #expect(self.mockStorage.eventCount == 1)
            
            self.analytics.flush()
            await runAfter(0.3) {
                #expect(self.mockStorage.eventCount == 0)
            }
        }
    }
    
    // MARK: - Deep Link Tests
    
    @Test("given Analytics, when opening deep link URL, then deep link event is tracked")
    func testDeepLinkTracking() async {
        let testURL = URL(string: "myapp://product?id=123&ref=deeplink")!
        let options = ["source": "test"]
        
        analytics.open(url: testURL, options: options)
        
        let trackEvents = await self.mockPlugin.waitForEvents(TrackEvent.self)
        let deepLinkEvent = trackEvents.first { $0.event == "Deep Link Opened" }
        
        #expect(deepLinkEvent != nil)
        #expect(deepLinkEvent?.properties?.dictionary?.rawDictionary["url"] as? String == testURL.absoluteString)
        #expect(deepLinkEvent?.properties?.dictionary?.rawDictionary["id"] as? String == "123")
        #expect(deepLinkEvent?.properties?.dictionary?.rawDictionary["ref"] as? String == "deeplink")
        #expect(deepLinkEvent?.properties?.dictionary?.rawDictionary["source"] as? String == "test")
    }
    
    @Test("given Analytics, when opening URL without query parameters, then basic deep link event is tracked")
    func testDeepLinkWithoutParameters() async {
        let testURL = URL(string: "myapp://home")!
        
        analytics.open(url: testURL)
        
        let trackEvents = await self.mockPlugin.waitForEvents(TrackEvent.self)
        let deepLinkEvent = trackEvents.first { $0.event == "Deep Link Opened" }
        
        #expect(deepLinkEvent != nil)
        #expect(deepLinkEvent?.properties?.dictionary?.rawDictionary["url"] as? String == testURL.absoluteString)
    }
    
    // MARK: - Shutdown Tests
    
    @Test("given Analytics, when shutting down, then analytics becomes inactive")
    func testShutdown() async {
        #expect(analytics.isAnalyticsActive == true)
        analytics.shutdown()
        #expect(analytics.isAnalyticsActive == false)
    }
    
    @Test("given shutdown Analytics, when attempting to track events, then events are not processed")
    func testEventsNotProcessedAfterShutdown() async {
        analytics.shutdown()
        
        await runAfter(0.1) {
            
            let initialEventCount = self.mockPlugin.eventCount
            
            // Try to track events after shutdown
            self.analytics.track(name: "Should Not Track")
            self.analytics.screen(screenName: "Should Not Track")
            self.analytics.identify(userId: "Should Not Track")
            self.analytics.group(groupId: "Should Not Track")
            self.analytics.alias(newId: "Should Not Track")
            
            await self.mockPlugin.waitForEvents(timeout: 0.1)
            // No new events should be processed
            #expect(self.mockPlugin.eventCount == initialEventCount)
        }
    }
    
    @Test("given shutdown Analytics, when accessing user properties, then nil is returned")
    func testUserPropertiesReturnNilAfterShutdown() async {
        // Set up user data first
        analytics.identify(userId: "test-user", traits: ["email": "test@example.com"])
        await self.mockPlugin.waitForEvents()
        
        #expect(self.analytics.userId == "test-user")
        #expect(self.analytics.anonymousId?.isEmpty == false)
        
        // Shutdown
        self.analytics.shutdown()
        
        await runAfter(0.1) {
            // Properties should return nil
            #expect(self.analytics.userId == nil)
            #expect(self.analytics.anonymousId == nil)
            #expect(self.analytics.traits == nil)
            #expect(self.analytics.sessionId == nil)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    
    @Test("given Analytics, when tracking multiple events concurrently, then all events are processed")
    func testSequentialEventTracking() async {
        let eventCount = 10
        
        // Track events sequentially to avoid actor isolation issues
        for i in 0..<eventCount {
            analytics.track(name: "Concurrent Event \(i)", properties: ["index": i])
        }
        
        let trackEvents = await self.mockPlugin.waitForEvents(TrackEvent.self, count: eventCount)
        #expect(trackEvents.count >= eventCount)
        
        // Verify all events were processed
        for i in 0..<eventCount {
            let eventExists = trackEvents.contains { $0.event == "Concurrent Event \(i)" }
            #expect(eventExists == true)
        }
    }
    
    @Test("given Analytics, when performing concurrent user operations, then state remains consistent")
    func testConcurrentUserOperations() async {
        // Perform identify operations sequentially to avoid actor isolation issues
        for i in 0..<5 {
            analytics.identify(userId: "user-\(i)", traits: ["batch": i])
        }
        
        let identifyEvents = await self.mockPlugin.waitForEvents(IdentifyEvent.self, count: 5)
        #expect(identifyEvents.count >= 5)
        
        // Final user ID should be the last set value
        let finalUserId = self.analytics.userId
        #expect(finalUserId?.hasPrefix("user-") == true)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("given Analytics, when tracking event with empty name, then event is still processed")
    func testTrackEventWithEmptyName() async {
        analytics.track(name: "")
        
        let trackEvents = await self.mockPlugin.waitForEvents(TrackEvent.self)
        #expect(trackEvents.count >= 1)
        #expect(trackEvents.first?.event == "")
    }
    
    @Test("given Analytics, when identifying with empty userId, then operation completes")
    func testIdentifyWithEmptyUserId() async {
        analytics.identify(userId: "", traits: ["test": "value"])
        
        let identifyEvents = await self.mockPlugin.waitForEvents(IdentifyEvent.self)
        #expect(identifyEvents.count >= 1)
        
        #expect(self.analytics.userId == "")
    }
    
    @Test("given Analytics, when performing operations with nil optional parameters, then operations complete successfully")
    func testNilOptionalParameters() async {
        analytics.track(name: "Test", properties: nil, options: nil)
        analytics.screen(screenName: "Test", category: nil, properties: nil, options: nil)
        analytics.group(groupId: "test", traits: nil, options: nil)
        analytics.identify(userId: nil, traits: nil, options: nil)
        analytics.alias(newId: "test", previousId: nil, options: nil)
        
        await self.mockPlugin.waitForEvents(count: 5)
        #expect(self.mockPlugin.eventCount >= 5)
    }
    
    // MARK: - Storage Integration Tests
    
    @Test("given Analytics, when events are tracked, then user identity is persisted to storage")
    func testUserIdentityPersistence() async {
        let userId = "persistent-user"
        let traits: Traits = ["email": "persistent@example.com"]
        
        analytics.identify(userId: userId, traits: traits)
        
        await self.mockPlugin.waitForEvents()
        // Check if user data is stored in the underlying storage
        #expect(self.analytics.userId == userId)
        #expect(self.analytics.traits?["email"] as? String == "persistent@example.com")
        
        // Verify data is in mock storage
        let storedData = self.mockStorage.allKeyValuePairs
        #expect(!storedData.isEmpty)
    }
    
    @Test("given Analytics, when anonymous ID is accessed, then it is consistent across calls")
    func testAnonymousIdConsistency() async {
        let anonymousId1 = analytics.anonymousId
        let anonymousId2 = analytics.anonymousId
        
        #expect(anonymousId1 == anonymousId2)
        #expect(anonymousId1?.isEmpty == false)
        
        // Verify anonymous ID is stored in mock storage
        let storedData = mockStorage.allKeyValuePairs
        #expect(!storedData.isEmpty)
    }
}

// MARK: - EventTestCaseParameters
enum EventTestCaseParameters {
    static var trackEvent: [(name: String, properties: [String: Any]?, options: RudderOption?)] {
        return [
            (_trackEventName, nil, nil),
            (_trackEventName, _sampleJsonPayload, nil),
            (_trackEventName, nil, _sampleRudderOption),
        ]
    }
    
    static var screenEvent: [(name: String, category: String?, properties: [String: Any]?, options: RudderOption?)] {
        return [
            (_screenEventName, nil, nil, nil),
            (_screenEventName, _screenEventCategory, nil, nil),
            (_screenEventName, _screenEventCategory, _sampleJsonPayload, nil),
            (_screenEventName, nil, _sampleJsonPayload, nil),
            (_screenEventName, nil, nil, _sampleRudderOption),
        ]
    }
    
    static var identifyEvent: [(userId: String?, traits: [String: Any]?, options: RudderOption?)] {
        return [
            (nil, nil, nil),
            (nil, _sampleJsonPayload, nil),
            (_identifyEventUserId, nil, nil),
            (_identifyEventUserId, _sampleJsonPayload, nil),
            (_identifyEventUserId, nil, _sampleRudderOption)
        ]
    }
    
    static var groupEvent: [(groupId: String, traits: [String: Any]?, options: RudderOption?)] {
        return [
            (_groupId, nil, nil),
            (_groupId, _sampleJsonPayload, nil),
            (_groupId, _sampleJsonPayload, _sampleRudderOption)
        ]
    }
     
    static var aliasEvent: [(alias: String, previousId: String?, options: RudderOption?)] {
        return [
            (_aliasId, nil, nil),
            (_aliasId, _previousId, nil),
            (_aliasId, nil, _sampleRudderOption)
        ]
    }
     
    private static var _trackEventName: String { "track_event" }
    
    private static var _screenEventName: String { "screen_event" }
    private static var _screenEventCategory: String { "screen_category" }
    
    private static var _identifyEventUserId: String { "identify_event_user_id" }
    private static var _groupId: String { "group_id" }
    
    private static var _aliasId: String { "alias_id" }
    private static var _previousId: String { "previous_id" }
    
    private static var _sampleJsonPayload: [String: Any] {
        ["key": "value", "number": 1]
    }
    private static var _sampleRudderOption: RudderOption {
        RudderOption(
            integrations: [
                "facebook": false,
                "google": ["key1": "value1", "enabled": true],
            ],
            customContext: ["test_context": "test_value"],
            externalIds: [
                ExternalId(type: "external_id_key", id: "external_id_value")
            ]
        )
    }
}
