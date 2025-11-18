//
//  FrequencyFlushPolicyTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Testing
@testable import RudderStackAnalytics
import Foundation

@Suite("FrequencyFlushPolicy Tests")
struct FrequencyFlushPolicyTests {
    
    // MARK: - Initialization Tests
    
    @Test("when policy is created, then uses correct default flush interval")
    func testDefaultInitializationUsesCorrectValues() {
        let policy = FrequencyFlushPolicy()
        
        #expect(policy.flushIntervalInMillis == Constants.flushInterval.default)
    }
    
    // MARK: - Invalid Value Handling Tests
    
    @Test("given invalid flush interval value, when policy is initialized, then falls back to default value",
          arguments: [Constants.flushInterval.min - 1, 0, 1])
    func testInvalidFlushIntervalValueFallsBackToDefault(_ flushInterval: UInt64) {
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: flushInterval)
        
        #expect(policy.flushIntervalInMillis == Constants.flushInterval.default)
    }
    
    // MARK: - Timer Scheduling Tests
    
    @Test("given policy with analytics, when schedule flush is called, then timer should be created")
    func testScheduleFlushCreatesTimer() {
        let flushInterval: UInt64 = 1001
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: flushInterval)
        let analytics = MockAnalytics()
        
        policy.scheduleFlush(analytics: analytics)
        
        waitForFlushInterval(flushInterval)
        
        #expect(analytics.isFlushed, "Expected analytics.flush() to be triggered by scheduled timer")
        
        policy.cancelScheduleFlush()
    }
    
    @Test("given scheduled policy, when cancel schedule flush is called, then timer should be cancelled")
    func testCancelScheduleFlushStopsTimer() {
        
        let flushInterval: UInt64 = 1500
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: flushInterval)
        let analytics = MockAnalytics()
        
        policy.scheduleFlush(analytics: analytics)
        policy.cancelScheduleFlush()
        
        waitForFlushInterval(flushInterval)
        
        #expect(!analytics.isFlushed, "Expected analytics.flush() should not be triggered by scheduled timer")
    }
    
    @Test("when schedule flush is called multiple times, then handles redundant scheduling safely")
    func testMultipleScheduleCallsAreSafe() {
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: 2000)
        let analytics = MockAnalytics()
        
        policy.scheduleFlush(analytics: analytics)
        policy.scheduleFlush(analytics: analytics) // Multiple calls
        policy.scheduleFlush(analytics: analytics) // Should handle safely
        
        #expect(!analytics.isFlushed) // Should not be flushed immediately
        
        policy.cancelScheduleFlush()
    }
    
    // MARK: - Timer Interval Validation Tests
    
    @Test("given various valid intervals, when policies are created, then all accept their respective values",
    arguments: [
        Constants.flushInterval.min,
        Constants.flushInterval.min + 500,
        Constants.flushInterval.default,
        Constants.flushInterval.default + 5000,
        50000 // 50 seconds
    ])
    func testVariousValidIntervalsAreAccepted(_ interval: UInt64) {
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: interval)
        
        #expect(policy.flushIntervalInMillis == interval, "Should accept valid interval: \(interval)")
    }
    
    
    // MARK: - Timer Behavior Tests
    
    @Test("given very short interval policy, when scheduled, then handles frequent timer events")
    func testVeryShortIntervalHandling() {
        let shortInterval = Constants.flushInterval.min // Minimum allowed
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: shortInterval)
        let analytics = MockAnalytics()
        
        policy.scheduleFlush(analytics: analytics)
        
        waitForFlushInterval(shortInterval)
        #expect(policy.flushIntervalInMillis == shortInterval)
        #expect(analytics.isFlushed)
        
        policy.cancelScheduleFlush()
    }
    
    @Test("given policy with large interval, when scheduled, then accepts large values correctly")
    func testLargeIntervalHandling() {
        let largeInterval: UInt64 = 3600000 // 1 hour in milliseconds
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: largeInterval)
        let analytics = MockAnalytics()
        
        policy.scheduleFlush(analytics: analytics)
        
        #expect(policy.flushIntervalInMillis == largeInterval)
        #expect(!analytics.isFlushed) // Should not flush immediately
        
        policy.cancelScheduleFlush()
    }
    
    // MARK: - State Consistency Tests
    
    @Test("given policy with operations, when various operations are performed, then flush interval property remains immutable")
    func testFlushIntervalPropertyRemainsImmutable() {
        let originalInterval: UInt64 = 3000
        let policy = FrequencyFlushPolicy(flushIntervalInMillis: originalInterval)
        let analytics = MockAnalytics()
        let initialInterval = policy.flushIntervalInMillis
        
        policy.scheduleFlush(analytics: analytics)
        policy.cancelScheduleFlush()
        policy.scheduleFlush(analytics: analytics)
        policy.cancelScheduleFlush()
        
        #expect(policy.flushIntervalInMillis == initialInterval, "flush interval should remain constant after operations")
        #expect(policy.flushIntervalInMillis == originalInterval, "flush interval should equal original value")
    }
    
    // MARK: - Integration Tests
    
    @Test("given policy with default configuration, when used in typical workflow, then behaves correctly")
    func testTypicalWorkflowBehavior() {
        let policy = FrequencyFlushPolicy() // Default configuration
        let analytics = MockAnalytics()
        
        // Typical usage pattern
        // 1. Schedule flush
        policy.scheduleFlush(analytics: analytics)
        #expect(!analytics.isFlushed) // Should not flush immediately
        
        // 2. Cancel after some usage
        policy.cancelScheduleFlush()
        
        // 3. Reschedule later
        policy.scheduleFlush(analytics: analytics)
        
        // Should work correctly throughout
        #expect(policy.flushIntervalInMillis == Constants.flushInterval.default)
        #expect(!analytics.isFlushed) // Should not flush immediately after rescheduling
        
        policy.cancelScheduleFlush()
    }
}

// MARK: - Helpers
extension FrequencyFlushPolicyTests {
    func waitForFlushInterval(_ flushIntervalInMillis: UInt64, buffer: TimeInterval = 0.1) {
        let waitDuration = Double(flushIntervalInMillis) / 1000.0 + buffer
        RunLoop.current.run(until: Date().addingTimeInterval(waitDuration))
    }
}
