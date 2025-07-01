//
//  SessionTrackingPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 27/02/25.
//

import XCTest
@testable import RudderStackAnalytics

final class SessionTrackingPluginTests: XCTestCase {
    
    private var analytics = MockProvider.clientWithMemoryStorage
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func test_intercept_trackEvent() {
        given("Manual session is started..") {
            let plugin = SessionTrackingPlugin()
            plugin.setup(analytics: self.analytics)
            
            self.analytics.sessionHandler?.startSession(id: 1231231234, type: .manual)
            let track = TrackEvent(event: "Track")
            
            when("A simple track event is sent to the session tracking plugin..") {
                let interceptedEvent = plugin.intercept(event: track)
                
                then("Track event should have the session info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["sessionId"])
                    XCTAssertNotNil(context["sessionStart"])
                }
            }
        }
    }
    
    func test_intercept_mulitple_groupEvent() {
        given("Start the session and trigger the first group event to the session tracking plugin..") {
            let plugin = SessionTrackingPlugin()
            plugin.setup(analytics: self.analytics)
        
            self.analytics.sessionHandler?.startSession(id: 1231231234, type: .manual)
            
            let group = GroupEvent(groupId: "Group_id")
            var interceptedEvent = plugin.intercept(event: group)
            
            when("call the intercept and trigger second event..") {
                let group2 = GroupEvent(groupId: "Group_id2")
                interceptedEvent = plugin.intercept(event: group2)
                
                then("Group event should have the session id only..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["sessionId"])
                    XCTAssertNil(context["sessionStart"])
                }
            }
        }
    }
}
