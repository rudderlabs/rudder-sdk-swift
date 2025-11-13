//
//  IdentifyEventTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 25/01/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("IdentifyEvent Tests")
struct IdentifyEventTests {
    
    @Test("given an identify event with default values, when serialized, then matches expected JSON")
    func testDefaultIdentifyEvent() {
        var event: Event = IdentifyEvent(userIdentity: UserIdentity(userId: "Test_User_Id"))
        event = event.updateEventData()
        MockHelper.resetDynamicValues(&event)
        
        guard let json = event.jsonString?.trimmed else { 
            Issue.record("\(errorMessageFailedToSerialize)")
            return
        }
        
        guard let expected = SwiftTestMockProvider.readJson(from: "identify_with_default_arguments")?.trimmed else { 
            Issue.record("\(errorMessageFailedToRead)")
            return
        }
        
        #expect(json == expected)
    }

     @Test("given an identify event with traits, when serialized, then matches expected JSON")
     func testIdentifyEventTraits() {
         var event: Event = IdentifyEvent(userIdentity: UserIdentity(userId: "Test_User_Id", traits: MockProvider.sampleEventproperties))
         event = event.updateEventData()
         MockHelper.resetDynamicValues(&event)
         
         guard let json = event.jsonString?.trimmed else { 
             Issue.record("\(errorMessageFailedToSerialize)")
             return
         }
         
         guard let expected = SwiftTestMockProvider.readJson(from: "identify_with_traits")?.trimmed else { 
             Issue.record("\(errorMessageFailedToRead)")
             return
         }
         
         #expect(json == expected)
     }
     
     @Test("given an identify event with options, when serialized, then matches expected JSON")
     func testIdentifyEventOptions() {
         let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties])
         
         var event: Event = IdentifyEvent(options: option, userIdentity: UserIdentity(userId: "Test_User_Id"))
         event = event.updateEventData()
         MockHelper.resetDynamicValues(&event)
         
         guard let json = event.jsonString?.trimmed else { 
             Issue.record("\(errorMessageFailedToSerialize)")
             return
         }
         
         guard let expected = SwiftTestMockProvider.readJson(from: "identify_with_options")?.trimmed else { 
             Issue.record("\(errorMessageFailedToRead)")
             return
         }
         
         #expect(json == expected)
     }
     
     @Test("given an identify event with traits and options, when serialized, then matches expected JSON")
     func testIdentifyEventTraitsOptions() {
         let option = RudderOption(integrations: MockProvider.sampleEventIntegrations, customContext: ["customContext": MockProvider.sampleEventproperties], externalIds: [ExternalId(type: "sample_Type", id: "sample_Id")])
         
         var event: Event = IdentifyEvent(options: option, userIdentity: UserIdentity(userId: "Test_User_Id", traits: MockProvider.sampleEventproperties))
         event = event.updateEventData()
         MockHelper.resetDynamicValues(&event)
         
         guard let json = event.jsonString?.trimmed else { 
             Issue.record("\(errorMessageFailedToSerialize)")
             return
         }
         
         guard let expected = SwiftTestMockProvider.readJson(from: "identify_with_all_values")?.trimmed else { 
             Issue.record("\(errorMessageFailedToRead)")
             return
         }
         
         #expect(json == expected)
     }
}

// MARK: - Error Messages
extension IdentifyEventTests{
    private var errorMessageFailedToSerialize: String { "Failed to serialize the event." }
    private var errorMessageFailedToRead: String { "Failed to read the expected JSON." }
}
