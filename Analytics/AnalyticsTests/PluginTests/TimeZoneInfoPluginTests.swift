//
//  TimeZoneInfoPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import XCTest
@testable import Analytics

final class TimeZoneInfoPluginTests: XCTestCase {
    
    func test_execute_trackEvent() {
        given("An simple track event to the time zone info plugin..") {
            let plugin = TimeZoneInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("execute is called..") {
                let executedEvent = plugin.execute(event: track)
                
                then("track event should have the time zone info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["timezone"])
                }
            }
        }
    }
    
    func test_execute_groupEvent() {
        given("An simple group event to the time zone info plugin..") {
            let plugin = TimeZoneInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("execute is called..") {
                let executedEvent = plugin.execute(event: group)
                
                then("group event should have the time zone info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["timezone"])
                }
            }
        }
    }
}
