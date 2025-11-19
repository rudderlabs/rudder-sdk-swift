//
//  NetworkInfoPluginTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 16/12/24.
//

import Testing
import Network
@testable import RudderStackAnalytics

@Suite("NetworkInfoPlugin Tests")
class NetworkInfoPluginTests {
    var networkInfoPlugin: NetworkInfoPlugin
    
    init() {
        self.networkInfoPlugin = NetworkInfoPlugin()
    }
    
    @Test("when intercepting different events, then adds network context information", arguments:[
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func test_pluginIntercept(_ event: Event) {
        let analytics = MockProvider.createMockAnalytics()
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
    }
    
    @Test("given mock network utils for wifi, when intercepting event, then uses mock connectivity data")
    func test_pluginInterceptWithMockNetworkUtilsWiFi() {
        // Create a mock network monitor that simulates WiFi connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.wifi])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = MockProvider.mockTrackEvent
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
        // Create a mock network monitor that simulates cellular connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.cellular])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = MockProvider.mockTrackEvent
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
        let analytics = MockProvider.createMockAnalytics()
        
        networkInfoPlugin.setup(analytics: analytics)
        
        #expect(networkInfoPlugin.analytics != nil)
        #expect(networkInfoPlugin.pluginType == .preProcess)
    }
}

// MARK: - MockNetworkMonitor
class MockNetworkMonitor: NetworkMonitorProtocol {
    var status: NWPath.Status
    var interfaces: [NWInterface.InterfaceType]
    
    init(status: NWPath.Status, interfaces: [NWInterface.InterfaceType]) {
        self.status = status
        self.interfaces = interfaces
    }
    
    func usesInterfaceType(_ type: NWInterface.InterfaceType) -> Bool {
        return interfaces.contains(type)
    }
    
    func start(queue: DispatchQueue) {
        // Simulate path update
    }
    
    func cancel() {
        // Simulate cancel behavior
    }
}
