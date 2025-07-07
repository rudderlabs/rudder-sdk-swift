//
//  RudderOptionTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 02/07/25.
//

import XCTest
@testable import RudderStackAnalytics

final class RudderOptionTests: XCTestCase {
    
    // MARK: - RudderOption Initialization Tests
    
    func test_rudderOption_defaultInitialization() {
        given("A RudderOption with default initialization") {
            let option = RudderOption()
            
            when("Checking the initialized values") {
                then("integrations should contain default values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                }
                
                then("customContext should be nil") {
                    XCTAssertNil(option.customContext)
                }
                
                then("externalIds should be nil") {
                    XCTAssertNil(option.externalIds)
                }
            }
        }
    }
    
    func test_rudderOption_initializationWithIntegrations() {
        given("A RudderOption with custom integrations") {
            let customIntegrations = ["Amplitude": true, "Firebase": false]
            let option = RudderOption(integrations: customIntegrations)
            
            when("Checking the initialized values") {
                then("integrations should contain both default and custom values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                    XCTAssertEqual(option.integrations?["Amplitude"] as? Bool, true)
                    XCTAssertEqual(option.integrations?["Firebase"] as? Bool, false)
                }
                
                then("customContext should be nil") {
                    XCTAssertNil(option.customContext)
                }
                
                then("externalIds should be nil") {
                    XCTAssertNil(option.externalIds)
                }
            }
        }
    }
    
    func test_rudderOption_initializationWithCustomContext() {
        given("A RudderOption with custom context") {
            let customContext = ["userId": "test_user", "sessionId": "session_123"]
            let option = RudderOption(customContext: customContext)
            
            when("Checking the initialized values") {
                then("integrations should contain default values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                }
                
                then("customContext should contain the provided values") {
                    XCTAssertNotNil(option.customContext)
                    XCTAssertEqual(option.customContext?["userId"] as? String, "test_user")
                    XCTAssertEqual(option.customContext?["sessionId"] as? String, "session_123")
                }
                
                then("externalIds should be nil") {
                    XCTAssertNil(option.externalIds)
                }
            }
        }
    }
    
    func test_rudderOption_initializationWithExternalIds() {
        given("A RudderOption with external IDs") {
            let externalIds = [
                ExternalId(type: "google", id: "google_user_123"),
                ExternalId(type: "facebook", id: "fb_user_456")
            ]
            let option = RudderOption(externalIds: externalIds)
            
            when("Checking the initialized values") {
                then("integrations should contain default values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                }
                
                then("customContext should be nil") {
                    XCTAssertNil(option.customContext)
                }
                
                then("externalIds should contain the provided values") {
                    XCTAssertNotNil(option.externalIds)
                    XCTAssertEqual(option.externalIds?.count, 2)
                    XCTAssertEqual(option.externalIds?[0].type, "google")
                    XCTAssertEqual(option.externalIds?[0].id, "google_user_123")
                    XCTAssertEqual(option.externalIds?[1].type, "facebook")
                    XCTAssertEqual(option.externalIds?[1].id, "fb_user_456")
                }
            }
        }
    }
    
    func test_rudderOption_fullInitialization() {
        given("A RudderOption with all parameters") {
            let customIntegrations = ["Amplitude": true, "Braze": false]
            let customContext = ["experiment": "test_group", "feature_flag": true]
            let externalIds = [ExternalId(type: "internal", id: "internal_123")]
            
            let option = RudderOption(
                integrations: customIntegrations,
                customContext: customContext,
                externalIds: externalIds
            )
            
            when("Checking the initialized values") {
                then("integrations should contain both default and custom values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                    XCTAssertEqual(option.integrations?["Amplitude"] as? Bool, true)
                    XCTAssertEqual(option.integrations?["Braze"] as? Bool, false)
                }
                
                then("customContext should contain the provided values") {
                    XCTAssertNotNil(option.customContext)
                    XCTAssertEqual(option.customContext?["experiment"] as? String, "test_group")
                    XCTAssertEqual(option.customContext?["feature_flag"] as? Bool, true)
                }
                
                then("externalIds should contain the provided values") {
                    XCTAssertNotNil(option.externalIds)
                    XCTAssertEqual(option.externalIds?.count, 1)
                    XCTAssertEqual(option.externalIds?[0].type, "internal")
                    XCTAssertEqual(option.externalIds?[0].id, "internal_123")
                }
            }
        }
    }
    
    func test_rudderOption_nilParameterHandling() {
        given("A RudderOption with explicit nil parameters") {
            let option = RudderOption(
                integrations: nil,
                customContext: nil,
                externalIds: nil
            )
            
            when("Checking the initialized values") {
                then("integrations should still contain default values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                }
                
                then("customContext should be nil") {
                    XCTAssertNil(option.customContext)
                }
                
                then("externalIds should be nil") {
                    XCTAssertNil(option.externalIds)
                }
            }
        }
    }
    
    func test_rudderOption_emptyParameterHandling() {
        given("A RudderOption with empty parameters") {
            let option = RudderOption(
                integrations: [:],
                customContext: [:],
                externalIds: []
            )
            
            when("Checking the initialized values") {
                then("integrations should contain only default values") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?.count, 1)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, true)
                }
                
                then("customContext should be empty") {
                    XCTAssertNotNil(option.customContext)
                    XCTAssertEqual(option.customContext?.count, 0)
                }
                
                then("externalIds should be empty") {
                    XCTAssertNotNil(option.externalIds)
                    XCTAssertEqual(option.externalIds?.count, 0)
                }
            }
        }
    }
    
    func test_rudderOption_overrideDefaultIntegration() {
        given("A RudderOption with custom integration that overrides the default 'All' value") {
            let customIntegrations = ["All": false, "Amplitude": true, "Firebase": true]
            let option = RudderOption(integrations: customIntegrations)
            
            when("Checking the initialized values") {
                then("the custom 'All' value should override the default") {
                    XCTAssertNotNil(option.integrations)
                    XCTAssertEqual(option.integrations?["All"] as? Bool, false)
                    XCTAssertEqual(option.integrations?["Amplitude"] as? Bool, true)
                    XCTAssertEqual(option.integrations?["Firebase"] as? Bool, true)
                    XCTAssertEqual(option.integrations?.count, 3)
                }
                
                then("customContext should be nil") {
                    XCTAssertNil(option.customContext)
                }
                
                then("externalIds should be nil") {
                    XCTAssertNil(option.externalIds)
                }
            }
        }
    }
}
