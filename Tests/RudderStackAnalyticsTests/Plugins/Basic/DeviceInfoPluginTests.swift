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
    
    @Test("when intercepting different events, then adds device context information", arguments:[
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func testPluginIntercept(_ event: Event) {
        let analytics = MockProvider.createMockAnalytics()
        deviceInfoPlugin.setup(analytics: analytics)
        
        let result = deviceInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(DeviceInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("\(DeviceInfoPluginIssue.noDeviceInfo)")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
        #expect(deviceInfo["id"] != nil)
    }
    
    @Test("given Analytics with collectDeviceId enabled, when intercepting event, then includes device id")
    func testPluginInterceptWithDeviceIdCollection() {
        let config = MockProvider.createMockConfiguration()
        config.collectDeviceId = true
        let analytics = Analytics(configuration: config)
        deviceInfoPlugin.setup(analytics: analytics)
        
        let trackEvent = MockProvider.mockTrackEvent
        let result = deviceInfoPlugin.intercept(event: trackEvent)
        
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(DeviceInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("\(DeviceInfoPluginIssue.noDeviceInfo)")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
        #expect(deviceInfo["id"] != nil)
    }
    
    @Test("given Analytics with collectDeviceId disabled, when intercepting event, then excludes device id")
    func testPluginInterceptWithoutDeviceIdCollection() {
        let config = MockProvider.createMockConfiguration()
        config.collectDeviceId = false
        let analytics = Analytics(configuration: config)
        deviceInfoPlugin.setup(analytics: analytics)
        
        let trackEvent = MockProvider.mockTrackEvent
        let result = deviceInfoPlugin.intercept(event: trackEvent)
        
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(DeviceInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["device"] != nil)
        guard let deviceInfo = context["device"] as? [String: Any] else {
            Issue.record("\(DeviceInfoPluginIssue.noDeviceInfo)")
            return
        }
        
        #expect(deviceInfo["manufacturer"] as? String == "Apple")
        #expect(deviceInfo["name"] != nil)
        #expect(deviceInfo["type"] != nil)
        #expect(deviceInfo["id"] == nil)
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        deviceInfoPlugin.setup(analytics: analytics)
        
        #expect(deviceInfoPlugin.analytics != nil)
        #expect(deviceInfoPlugin.pluginType == .preProcess)
    }
}

enum DeviceInfoPluginIssue {
    static let noDeviceInfo: String = "Device info not found"
    static let noEventContext: String = "Event context not found"
}
