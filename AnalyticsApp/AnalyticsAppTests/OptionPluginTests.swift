//
//  OptionPluginTests.swift
//  AnalyticsAppTests
//
//  Created by Satheesh Kannan on 26/03/25.
//

import Testing
import Analytics
@testable import AnalyticsApp

struct OptionPluginTests {
    
    @Test
    func test_whenOptionIsPresent() {
        given("An OptionPlugin initialized with a custom option") {
            let customContext = ["key1": "value1"]
            let integrations = ["integration1": true]
            let extenalId = ExternalId(type: "external_Id_Type", id: "external_Id")
            
            let option = RudderOption(integrations: integrations, customContext: customContext, externalIds: [extenalId])
            let plugin = OptionPlugin(option: option)
            
            when("Intercepting a mock event") {
                let mockEvent = MockEvent()
                let result = plugin.intercept(event: mockEvent)
                
                then("The event should be updated with the provided context and integrations") {
                    #expect(result != nil)
                    
                    guard let context = result?.context as? [String: Any] else { #expect(1 == 0, "Custom context not added"); return }
                    #expect(context["key1"] != nil)
                    
                    guard let integrations = result?.integrations as? [String: Any] else { #expect(1 == 0, "Integrations not added"); return }
                    #expect(integrations["integration1"] != nil)
                    
                    guard let externalIds = context["externalId"] as? [String: Any] else { #expect(1 == 0, "External IDs not added"); return }
                    #expect(externalIds["id"] as? String == "external_Id")
                    #expect(externalIds["type"] as? String == "external_id_type")
                }
            }
        }
    }
}
