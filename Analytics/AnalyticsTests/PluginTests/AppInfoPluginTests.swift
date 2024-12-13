//
//  AppInfoPluginTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 13/12/24.
//

import XCTest
@testable import Analytics

final class AppInfoPluginTests: XCTestCase {
    
    func test_execute_trackEvent() {
        given("An simple track event to the app info plugin..") {
            let plugin = AppInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("execute is called..") {
                let executedEvent = plugin.execute(event: track)
                
                then("track event should have the app info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["app"])
                }
            }
        }
    }
    
    func test_execute_groupEvent() {
        given("An simple group event to the app info plugin..") {
            let plugin = AppInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("execute is called..") {
                let executedEvent = plugin.execute(event: group)
                
                then("group event should have the app info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["app"])
                }
            }
        }
    }
}
