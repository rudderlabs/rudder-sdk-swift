//
//  FlushPolicyFacadeTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("FlushPolicyFacade Tests")
struct FlushPolicyFacadeTests {
        
    @Test("given analytics instance, when facade is created, then initializes correctly")
    func testFacadeInitialization() {
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = []
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        #expect(facade.activePolicies.isEmpty)
    }
    
    @Test("given analytics with multiple flush policies, when facade is created, then reflects active policies correctly")
    func testFacadeWithMultiplePolicies() {
        let startupPolicy = StartupFlushPolicy()
        let countPolicy = CountFlushPolicy(flushAt: 5)
        let frequencyPolicy = FrequencyFlushPolicy(flushIntervalInMillis: 2000)
        
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [startupPolicy, countPolicy, frequencyPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        #expect(facade.activePolicies.count == 3)
    }
        
    @Test("given facade with startup policy, when shouldflush is called first time, then returns true")
    func testShouldFlushWithStartupPolicyFirstCall() {
        let startupPolicy = StartupFlushPolicy()
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [startupPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        #expect(facade.shouldFlush())
    }
    
    @Test("given facade with count policy at threshold, when shouldflush is called, then returns true")
    func testShouldFlushWithCountPolicyAtThreshold() {
        let countPolicy = CountFlushPolicy(flushAt: 3)
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [countPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        for _ in 1...3 {
            facade.updateCount()
        }
        
        #expect(facade.shouldFlush())
    }
    
    @Test("given facade with frequency policy only, when shouldflush is called immediately, then returns false")
    func testShouldFlushWithFrequencyPolicyOnly() {
        let frequencyPolicy = FrequencyFlushPolicy(flushIntervalInMillis: 2000)
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [frequencyPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        #expect(!facade.shouldFlush())
        facade.cancelSchedule()
    }
        
    @Test("given facade with count policy, when updatecount and resetcount are called, then manages count correctly")
    func testCountManagement() {
        let countPolicy = CountFlushPolicy(flushAt: 3)
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [countPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        for _ in 1...3 {
            facade.updateCount()
        }
        #expect(facade.shouldFlush())
        
        facade.resetCount()
        
        #expect(!facade.shouldFlush())
    }
        
    @Test("given facade with mixed policies, when complete workflow is executed, then coordinates correctly")
    func testMixedPolicyWorkflow() {
        let startupPolicy = StartupFlushPolicy()
        let countPolicy = CountFlushPolicy(flushAt: 2)
        let frequencyPolicy = FrequencyFlushPolicy(flushIntervalInMillis: 2000)
        
        let configuration = SwiftTestMockProvider.createMockConfiguration()
        configuration.flushPolicies = [startupPolicy, countPolicy, frequencyPolicy]
        let analytics = Analytics(configuration: configuration)
        
        let facade = FlushPolicyFacade(analytics: analytics)
        
        //Startup policy should trigger flush initially
        #expect(facade.shouldFlush()) // StartupFlushPolicy triggers
        
        // Startup policy consumed, count below threshold
        _ = facade.shouldFlush() // Consumes startup policy
        #expect(!facade.shouldFlush()) // Neither policy triggers
        
        // Update count to threshold
        facade.updateCount()
        facade.updateCount()
        
        // Count policy should trigger
        #expect(facade.shouldFlush())
        
        // Reset count and manage schedule
        facade.resetCount()
        facade.startSchedule()
        facade.cancelSchedule()
        
        // No policies should trigger after reset
        #expect(!facade.shouldFlush())
    }
}
