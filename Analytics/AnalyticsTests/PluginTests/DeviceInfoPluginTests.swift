//
//  DeviceInfoModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 28/11/24.
//

import XCTest
@testable import Analytics

final class DeviceInfoPluginTests: XCTestCase {
    
    func test_pluginInitialization() {
        given("An analytics object given..") {
            let analytics = MockProvider.clientWithDiskStorage
            let plugin = DeviceInfoPlugin()
            
            when("plugin setup is called..") {
                plugin.setup(analytics: analytics)
                
                then("analytics property should be set..") {
                    XCTAssertNotNil(plugin.analytics)
                    XCTAssertTrue(plugin.collectDeviceId == analytics.configuration.collectDeviceId)
                }
            }
        }
    }
    
    func test_execute_trackEvent() {
        given("An simple track event to the device info plugin..") {
            let plugin = DeviceInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("intercept is called..") {
                let executedEvent = plugin.intercept(event: track)
                
                then("track event should have the device info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["device"])
                }
            }
        }
    }
    
    func test_execute_groupEvent() {
        given("An simple group event to the device info plugin..") {
            let plugin = DeviceInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("intercept is called..") {
                let executedEvent = plugin.intercept(event: group)
                
                then("group event should have the device info details..") {
                    guard let context = executedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["device"])
                }
            }
        }
    }
}
