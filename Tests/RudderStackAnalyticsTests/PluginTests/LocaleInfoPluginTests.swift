//
//  LocaleInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import XCTest
@testable import RudderStackAnalytics

final class LocaleInfoPluginTests: XCTestCase {
    
    func test_intercept_trackEvent() {
        given("An simple track event to the locale info plugin..") {
            let plugin = LocaleInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the locale info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["locale"])
                }
            }
        }
    }
    
    func test_intercept_groupEvent() {
        given("An simple group event to the locale info plugin..") {
            let plugin = LocaleInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: group)
                
                then("group event should have the locale info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["locale"])
                }
            }
        }
    }
}
