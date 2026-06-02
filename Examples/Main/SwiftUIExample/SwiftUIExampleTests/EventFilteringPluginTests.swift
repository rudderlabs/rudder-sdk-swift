//
//  EventFilteringPluginTests.swift
//  SwiftUIExampleAppTests
//
//  Created by Satheesh Kannan on 31/07/25.
//

import Testing
import RudderStackAnalytics
@testable import SwiftUIExampleApp

struct EventFilteringPluginTests {
    
    private var testConfiguration: Configuration {
        return Configuration(writeKey: "sample-write-key", dataPlaneUrl: "https://data-plane.analytics.com")
    }
    
    @Test
    func test_whenEventShouldBeFiltered() {
        given("An EventFilteringPlugin initialized with default events") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin()
            plugin.setup(analytics: analytics)
            
            when("Intercepting a TrackEvent with a filtered event name") {
                let filteredEvent = TrackEvent(event: "Application Opened")
                let result = plugin.intercept(event: filteredEvent)
                
                then("The event should be filtered out (returns nil)") {
                    #expect(result == nil)
                }
            }
        }
    }
    
    @Test
    func test_whenEventShouldNotBeFiltered() {
        given("An EventFilteringPlugin initialized with default events") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin()
            plugin.setup(analytics: analytics)
            
            when("Intercepting a TrackEvent with a non-filtered event name") {
                let allowedEvent = TrackEvent(event: "Product Purchased")
                let result = plugin.intercept(event: allowedEvent)
                
                then("The event should pass through unchanged") {
                    #expect(result != nil)
                    guard let trackResult = result as? TrackEvent else {
                        #expect(Bool(false), "Result should be a TrackEvent")
                        return
                    }
                    #expect(trackResult.event == "Product Purchased")
                }
            }
        }
    }
    
    @Test
    func test_whenMultipleEventsAreFiltered() {
        given("An EventFilteringPlugin initialized with default events") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin()
            plugin.setup(analytics: analytics)
            
            when("Intercepting multiple events with different filtered event names") {
                let filteredEvent1 = TrackEvent(event: "Application Opened")
                let filteredEvent2 = TrackEvent(event: "Application Backgrounded")
                
                let result1 = plugin.intercept(event: filteredEvent1)
                let result2 = plugin.intercept(event: filteredEvent2)
                
                then("Both events should be filtered out") {
                    #expect(result1 == nil)
                    #expect(result2 == nil)
                }
            }
        }
    }
    
    @Test
    func test_whenNonTrackEventIsIntercepted() {
        given("An EventFilteringPlugin initialized with default events") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin()
            plugin.setup(analytics: analytics)
            
            when("Intercepting a non-TrackEvent (MockEvent)") {
                let mockEvent = MockEvent()
                let result = plugin.intercept(event: mockEvent)
                
                then("The event should pass through unchanged") {
                    #expect(result != nil)
                    #expect(result?.type == .track)
                }
            }
        }
    }
    
    @Test
    func test_whenCustomEventsAreFiltered() {
        given("An EventFilteringPlugin initialized with custom events to filter") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let customEvents = ["Custom Event", "Unwanted Event"]
            let plugin = EventFilteringPlugin(eventsToFilter: customEvents)
            plugin.setup(analytics: analytics)
            
            when("Intercepting TrackEvents with custom filtered event names") {
                let filteredEvent1 = TrackEvent(event: "Custom Event")
                let filteredEvent2 = TrackEvent(event: "Unwanted Event")
                let allowedEvent = TrackEvent(event: "Application Opened") // Default event but not in custom list
                
                let result1 = plugin.intercept(event: filteredEvent1)
                let result2 = plugin.intercept(event: filteredEvent2)
                let result3 = plugin.intercept(event: allowedEvent)
                
                then("Custom events should be filtered out, default events should pass through") {
                    #expect(result1 == nil)
                    #expect(result2 == nil)
                    #expect(result3 != nil)
                }
            }
        }
    }
    
    @Test
    func test_whenEmptyCustomEventsListIsProvided() {
        given("An EventFilteringPlugin initialized with empty events list") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin(eventsToFilter: [])
            plugin.setup(analytics: analytics)
            
            when("Intercepting any TrackEvent") {
                let event1 = TrackEvent(event: "Application Opened")
                let event2 = TrackEvent(event: "Any Event")
                
                let result1 = plugin.intercept(event: event1)
                let result2 = plugin.intercept(event: event2)
                
                then("All events should pass through since nothing is filtered") {
                    #expect(result1 != nil)
                    #expect(result2 != nil)
                }
            }
        }
    }
    
    @Test
    func test_whenSingleCustomEventIsFiltered() {
        given("An EventFilteringPlugin initialized with single custom event") {
            let analytics = Analytics(configuration: self.testConfiguration)
            let plugin = EventFilteringPlugin(eventsToFilter: ["Specific Event"])
            plugin.setup(analytics: analytics)
            
            when("Intercepting the specific event and other events") {
                let filteredEvent = TrackEvent(event: "Specific Event")
                let allowedEvent1 = TrackEvent(event: "Application Opened")
                let allowedEvent2 = TrackEvent(event: "Product Purchased")
                
                let result1 = plugin.intercept(event: filteredEvent)
                let result2 = plugin.intercept(event: allowedEvent1)
                let result3 = plugin.intercept(event: allowedEvent2)
                
                then("Only the specific event should be filtered out") {
                    #expect(result1 == nil)
                    #expect(result2 != nil)
                    #expect(result3 != nil)
                }
            }
        }
    }
}
