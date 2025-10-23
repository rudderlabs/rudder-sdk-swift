//
//  NetworkInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/12/24.
//

import Testing
@testable import RudderStackAnalytics

@Suite("NetworkInfoPlugin Swift Tests")
class NetworkInfoPluginSwiftTests {
    var networkInfoPlugin: NetworkInfoPlugin
    
    init() {
        self.networkInfoPlugin = NetworkInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds network context information", arguments:[
        SwiftTestMockProvider.mockTrackEvent as Event,
        SwiftTestMockProvider.mockScreenEvent as Event,
        SwiftTestMockProvider.mockIdentifyEvent as Event,
        SwiftTestMockProvider.mockGroupEvent as Event,
        SwiftTestMockProvider.mockAliasEvent as Event
    ])
    func test_pluginIntercept(_ event: Event) {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        networkInfoPlugin.setup(analytics: analytics)
        
        let result = networkInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("network info not found")
            return
        }
        
        #expect(networkInfo["wifi"] != nil)
        #expect(networkInfo["cellular"] != nil)
        #expect(networkInfo["wifi"] is Bool)
        #expect(networkInfo["cellular"] is Bool)
    }
    
    @Test("given mock network utils for wifi, when intercepting event, then uses mock connectivity data")
    func test_pluginInterceptWithMockNetworkUtilsWiFi() {
        // Create a mock network monitor that simulates WiFi connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.wifi])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        let result = networkInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("network info not found")
            return
        }
        
        #expect(networkInfo["wifi"] as? Bool == true)
        #expect(networkInfo["cellular"] as? Bool == false)
    }
    
    @Test("given mock network utils for cellular, when intercepting event, then uses mock connectivity data")
    func test_pluginInterceptWithMockNetworkUtilsCellular() {
        // Create a mock network monitor that simulates WiFi connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.cellular])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = SwiftTestMockProvider.mockTrackEvent
        let result = networkInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("Event context not found")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("network info not found")
            return
        }
        
        #expect(networkInfo["wifi"] as? Bool == false)
#if os(tvOS)
        #expect(networkInfo["cellular"] as? Bool == false)
#else
        #expect(networkInfo["cellular"] as? Bool == true)
#endif
        
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func test_pluginSetup() {
        let analytics = SwiftTestMockProvider.createMockAnalytics()
        
        networkInfoPlugin.setup(analytics: analytics)
        
        #expect(networkInfoPlugin.analytics != nil)
        #expect(networkInfoPlugin.pluginType == .preProcess)
    }
}
