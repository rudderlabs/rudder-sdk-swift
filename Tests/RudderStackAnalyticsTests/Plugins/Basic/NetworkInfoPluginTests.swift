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
    
    @Test("when intercepting different events, then adds network context information", arguments: [
        MockProvider.mockTrackEvent as Event,
        MockProvider.mockScreenEvent as Event,
        MockProvider.mockIdentifyEvent as Event,
        MockProvider.mockGroupEvent as Event,
        MockProvider.mockAliasEvent as Event
    ])
    func testPluginIntercept(_ event: Event) {
        let analytics = MockProvider.createMockAnalytics()
        networkInfoPlugin.setup(analytics: analytics)
        
        let result = networkInfoPlugin.intercept(event: event)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(NetworkInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("\(NetworkInfoPluginIssue.noNetworkInfo)")
            return
        }
        
        #expect(networkInfo["wifi"] != nil)
        #expect(networkInfo["cellular"] != nil)
    }
    
    @Test("given mock network utils for wifi, when intercepting event, then uses mock connectivity data")
    func testPluginInterceptWithMockNetworkUtilsWiFi() {
        // Create a mock network monitor that simulates WiFi connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.wifi])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = MockProvider.mockTrackEvent
        let result = networkInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(NetworkInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("\(NetworkInfoPluginIssue.noNetworkInfo)")
            return
        }
        
        #expect(networkInfo["wifi"] as? Bool ?? false)
        #expect(!(networkInfo["cellular"] as? Bool ?? true))
    }
    
    @Test("given mock network utils for cellular, when intercepting event, then uses mock connectivity data")
    func testPluginInterceptWithMockNetworkUtilsCellular() {
        // Create a mock network monitor that simulates cellular connection
        let mockMonitor = MockNetworkMonitor(status: .satisfied, interfaces: [.cellular])
        let mockUtils = NetworkInfoPluginUtils(monitor: mockMonitor)
        networkInfoPlugin.networkInfoUtils = mockUtils
        
        let trackEvent = MockProvider.mockTrackEvent
        let result = networkInfoPlugin.intercept(event: trackEvent)
        
        #expect(result != nil)
        #expect(result?.context != nil)
        guard let context = result?.context?.rawDictionary else {
            Issue.record("\(NetworkInfoPluginIssue.noEventContext)")
            return
        }
        
        #expect(context["network"] != nil)
        guard let networkInfo = context["network"] as? [String: Any] else {
            Issue.record("\(NetworkInfoPluginIssue.noNetworkInfo)")
            return
        }
        
        #expect(!(networkInfo["wifi"] as? Bool ?? true))
#if os(tvOS)
        #expect(!(networkInfo["cellular"] as? Bool ?? true))
#else
        #expect(networkInfo["cellular"] as? Bool ?? false)
#endif
        
    }
    
    @Test("when setup is called, then analytics reference is stored")
    func testPluginSetup() {
        let analytics = MockProvider.createMockAnalytics()
        
        networkInfoPlugin.setup(analytics: analytics)
        
        #expect(networkInfoPlugin.analytics != nil)
        #expect(networkInfoPlugin.pluginType == .preProcess)
    }
}

// MARK: - NetworkInfoPluginIssue
enum NetworkInfoPluginIssue {
    static let noNetworkInfo: String = "Network info not found"
    static let noEventContext: String = "Event context not found"
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
