//
//  OSInfoPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 11/12/24.
//

import XCTest
@testable import Analytics

final class OSInfoPluginTests: XCTestCase {
    
    func test_intercept_trackEvent() {
        given("An simple track event to the os info plugin..") {
            let plugin = OSInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the os info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["os"])
                }
            }
        }
    }
    
    func test_intercept_groupEvent() {
        given("An simple group event to the os info plugin..") {
            let plugin = OSInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: group)
                
                then("group event should have the os info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["os"])
                }
            }
        }
    }
}

