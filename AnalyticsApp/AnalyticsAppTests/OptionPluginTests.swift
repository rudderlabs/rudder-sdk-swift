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
            let externalId = ExternalId(type: "external_id_type", id: "external_id")

            let option = RudderOption(integrations: integrations, customContext: customContext, externalIds: [externalId])
            let plugin = OptionPlugin(option: option)

            when("Intercepting a mock event") {
                let mockEvent = MockEvent()
                let result = plugin.intercept(event: mockEvent)

                then("The event should be updated with the provided context, integrations, and externalIds") {
                    #expect(result != nil)

                    guard let context = result?.context?.rawDictionary else {
                        #expect(Bool(false), "Context not available or not of expected type")
                        return
                    }
                    #expect(context["key1"] as? String == "value1")

                    guard let integrations = result?.integrations?.rawDictionary else {
                        #expect(Bool(false), "Integrations not available or not of expected type")
                        return
                    }
                    #expect(integrations["integration1"] as? Bool == true)

                    guard let externalIds = context["externalId"] as? [[String: Any]] else {
                        #expect(Bool(false), "externalId not available or not of expected type [[String: Any]]")
                        return
                    }

                    let match = externalIds.contains { dict in
                        dict["id"] as? String == "external_id" && dict["type"] as? String == "external_id_type"
                    }
                    #expect(match, "Expected externalId entry not found")
                }
            }
        }
    }
}
