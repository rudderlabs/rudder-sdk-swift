//
//  NetworkInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/12/24.
//

import XCTest
@testable import RudderStackAnalytics

final class NetworkInfoPluginTests: XCTestCase {
    
    func test_intercept_trackEvent() {
        given("An simple track event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                }
            }
        }
    }
    
    func test_intercept_groupEvent() {
        given("An simple group event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let group = GroupEvent(groupId: "group_id")
            
            when("intercept is called..") {
                let interceptedEvent = plugin.intercept(event: group)
                
                then("group event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                }
            }
        }
    }
    
    func test_wifi_cellular_enabled_trackEvent() {
        given("An simple track event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("Wifi and Cellular is enabled..") {
                let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.wifi, .cellular])
                let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
                plugin.networkInfoUtils = mockUtils
                
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                    
                    guard let codableInfo = context["network"], let networkInfo = codableInfo.value as? [String: Any] else { XCTFail("No network info found"); return }
                    
                    XCTAssertEqual(networkInfo["wifi"] as? Bool, true)
#if os(tvOS)
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, false)
#else
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, true)
#endif
                }
            }
        }
    }
    
    func test_wifi_enabled_trackEvent() {
        given("An simple track event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("Wifi and Cellular is enabled..") {
                let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.wifi])
                let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
                plugin.networkInfoUtils = mockUtils
                
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                    
                    guard let codableInfo = context["network"], let networkInfo = codableInfo.value as? [String: Any] else { XCTFail("No network info found"); return }
                    
                    XCTAssertEqual(networkInfo["wifi"] as? Bool, true)
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, false)
                }
            }
        }
    }
    
    func test_cellular_enabled_trackEvent() {
        given("An simple track event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("Wifi and Cellular is enabled..") {
                let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.cellular])
                let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
                plugin.networkInfoUtils = mockUtils
                
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                    
                    guard let codableInfo = context["network"], let networkInfo = codableInfo.value as? [String: Any] else { XCTFail("No network info found"); return }
                    
                    XCTAssertEqual(networkInfo["wifi"] as? Bool, false)
                    
#if os(tvOS)
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, false)
#else
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, true)
#endif
                }
            }
        }
    }
    
    func test_wifi_cellular_not_enabled_trackEvent() {
        given("An simple track event to the network info plugin..") {
            let plugin = NetworkInfoPlugin()
            let track = TrackEvent(event: "Track")
            
            when("Wifi and Cellular is enabled..") {
                let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [])
                let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
                plugin.networkInfoUtils = mockUtils
                
                let interceptedEvent = plugin.intercept(event: track)
                
                then("track event should have the network info details..") {
                    guard let context = interceptedEvent?.context else { XCTFail("No context found"); return }
                    XCTAssertNotNil(context["network"])
                    
                    guard let codableInfo = context["network"], let networkInfo = codableInfo.value as? [String: Any] else { XCTFail("No network info found"); return }
                    
                    XCTAssertEqual(networkInfo["wifi"] as? Bool, false)
                    XCTAssertEqual(networkInfo["cellular"] as? Bool, false)
                }
            }
        }
    }
}
