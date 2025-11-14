//
//  ScreenEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 20/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("ScreenEvent Tests")
struct ScreenEventTests {
    
    @Test("given a screen event with default values, when serialized, then matches expected JSON")
    func testDefaultScreenEvent() {
        var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }

        guard let expected = SwiftTestMockProvider.readJson(from: "screen_with_default_arguments")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }
    
    @Test("given a screen event with category, when serialized, then matches expected JSON")
    func testScreenEventCategory() {
        var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, category: "Main")
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "screen_with_category")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }
    
    @Test("given a screen event with properties, when serialized, then matches expected JSON")
    func testScreenEventProperties() {
        var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, properties: MockProvider.sampleEventproperties)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "screen_with_properties")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }
    
    @Test("given a screen event with options, when serialized, then matches expected JSON")
    func testScreenEventOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
        
        var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }

        guard let expected = SwiftTestMockProvider.readJson(from: "screen_with_options")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }
    
    @Test("given a screen event with category, properties and options, when serialized, then matches expected JSON")
    func testScreenEventCategoryPropertiesOptions() {
        let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
        
        var event: Event = ScreenEvent(screenName: MockProvider.SampleEventName.screen, category: "Main", properties: MockProvider.sampleEventproperties, options: option)
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "screen_with_all_values")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }
}

// MARK: - Error Messages
extension ScreenEventTests {
    private var errorMessageFailedToSerialize: String { "Failed to serialize the event." }
    private var errorMessageFailedToRead: String { "Failed to read the expected JSON." }
}
