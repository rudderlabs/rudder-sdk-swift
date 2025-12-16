//
//  RudderOptionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 02/07/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("RudderOption Tests")
struct RudderOptionTests {
    
    // MARK: - RudderOption Initialization Tests
    
    @Test("given a RudderOption with default initialization, when checked, then contains expected default values")
    func testRudderOptionDefaultInitialization() {
        let option = RudderOption()
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.customContext == nil)
        #expect(option.externalIds == nil)
    }
    
    @Test("given a RudderOption with custom integrations, when checked, then contains both default and custom values")
    func testRudderOptionInitializationWithIntegrations() {
        let customIntegrations = ["Amplitude": true, "Firebase": false]
        let option = RudderOption(integrations: customIntegrations)
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.integrations?["Amplitude"] as? Bool ?? false)
        #expect(!(option.integrations?["Firebase"] as? Bool ?? true))
        #expect(option.customContext == nil)
        #expect(option.externalIds == nil)
    }
    
    @Test("given a RudderOption with custom context, when checked, then contains provided custom context values")
    func testRudderOptionInitializationWithCustomContext() {
        let customContext = ["userId": "test_user", "sessionId": "session_123"]
        let option = RudderOption(customContext: customContext)
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.customContext != nil)
        #expect(option.customContext?["userId"] as? String == "test_user")
        #expect(option.customContext?["sessionId"] as? String == "session_123")
        #expect(option.externalIds == nil)
    }
    
    @Test("given a RudderOption with external IDs, when checked, then contains provided external ID values")
    func testRudderOptionInitializationWithExternalIds() {
        let externalIds = [
            ExternalId(type: "google", id: "google_user_123"),
            ExternalId(type: "facebook", id: "fb_user_456")
        ]
        let option = RudderOption(externalIds: externalIds)
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.customContext == nil)
        #expect(option.externalIds != nil)
        #expect(option.externalIds?.count == 2)
        #expect(option.externalIds?[0].type == "google")
        #expect(option.externalIds?[0].id == "google_user_123")
        #expect(option.externalIds?[1].type == "facebook")
        #expect(option.externalIds?[1].id == "fb_user_456")
    }
    
    @Test("given a RudderOption with all parameters, when checked, then contains all provided values")
    func testRudderOptionFullInitialization() {
        let customIntegrations = ["Amplitude": true, "Braze": false]
        let customContext: [String: Any] = ["experiment": "test_group", "feature_flag": true]
        let externalIds = [ExternalId(type: "internal", id: "internal_123")]
        
        let option = RudderOption(
            integrations: customIntegrations,
            customContext: customContext,
            externalIds: externalIds
        )
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.integrations?["Amplitude"] as? Bool ?? false)
        #expect(!(option.integrations?["Braze"] as? Bool ?? true))
        #expect(option.customContext != nil)
        #expect(option.customContext?["experiment"] as? String == "test_group")
        #expect(option.customContext?["feature_flag"] as? Bool ?? false)
        #expect(option.externalIds != nil)
        #expect(option.externalIds?.count == 1)
        #expect(option.externalIds?[0].type == "internal")
        #expect(option.externalIds?[0].id == "internal_123")
    }
    
    @Test("given a RudderOption with explicit nil parameters, when checked, then contains default integrations and nil values")
    func testRudderOptionNilParameterHandling() {
        let option = RudderOption(
            integrations: nil,
            customContext: nil,
            externalIds: nil
        )
        
        #expect(option.integrations != nil)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.customContext == nil)
        #expect(option.externalIds == nil)
    }
    
    @Test("given a RudderOption with empty parameters, when checked, then contains only default integrations and empty collections")
    func testRudderOptionEmptyParameterHandling() {
        let option = RudderOption(
            integrations: [:],
            customContext: [:],
            externalIds: []
        )
        
        #expect(option.integrations != nil)
        #expect(option.integrations?.count == 1)
        #expect(option.integrations?["All"] as? Bool ?? false)
        #expect(option.customContext != nil)
        #expect(option.customContext?.count == 0)
        #expect(option.externalIds != nil)
        #expect(option.externalIds?.count == 0)
    }
    
    @Test("given a RudderOption that overrides default 'All' integration, when checked, then custom 'All' value overrides default")
    func testRudderOptionOverrideDefaultIntegration() {
        let customIntegrations = ["All": false, "Amplitude": true, "Firebase": true]
        let option = RudderOption(integrations: customIntegrations)
        
        #expect(option.integrations != nil)
        #expect(!(option.integrations?["All"] as? Bool ?? true))
        #expect(option.integrations?["Amplitude"] as? Bool ?? false)
        #expect(option.integrations?["Firebase"] as? Bool ?? false)
        #expect(option.integrations?.count == 3)
        #expect(option.customContext == nil)
        #expect(option.externalIds == nil)
    }
}
