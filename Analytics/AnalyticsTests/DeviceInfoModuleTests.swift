//
//  DeviceInfoModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 28/11/24.
//

import XCTest
@testable import Analytics

final class DeviceInfoModuleTests: XCTestCase {
    
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
        
    }
}
