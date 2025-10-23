//
//  DeviceInfoModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 28/11/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("DeviceInfoPlugin Tests")
class DeviceInfoPluginTests {
    
    var deviceInfoPlugin: DeviceInfoPlugin
    
    init() {
        self.deviceInfoPlugin = DeviceInfoPlugin()
    }
    
    @Test("when intercepting event, then adds device context information")
    func testDeviceInfoPlugin_InterceptEvent() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        deviceInfoPlugin.setup(analytics: analytics)
        
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        let result = deviceInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("Device info not found")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
    }
    
    @Test("given Analytics with collectDeviceId enabled, when intercepting event, then includes device id")
    func testDeviceInfoPlugin_WithDeviceIdCollection() {
        let config = SwiftTestMockProvider.createMockConfiguration()
        config.collectDeviceId = true
        let analytics = Analytics(configuration: config)
        deviceInfoPlugin.setup(analytics: analytics)
        
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        let result = deviceInfoPlugin.intercept(event: trackEvent)
        
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("Device info not found")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
        #expect(deviceInfo["id"] != nil)
    }
    
    @Test("given Analytics with collectDeviceId disabled, when intercepting event, then excludes device id")
    func testDeviceInfoPlugin_WithoutDeviceIdCollection() {
        let config = SwiftTestMockProvider.createMockConfiguration()
        config.collectDeviceId = false
        let analytics = Analytics(configuration: config)
        deviceInfoPlugin.setup(analytics: analytics)
        
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        let result = deviceInfoPlugin.intercept(event: trackEvent)
        
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("Device info not found")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
        #expect(deviceInfo["id"] == nil)
    }
}
