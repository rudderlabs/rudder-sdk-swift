//
//  CountFlushPolicyTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("CountFlushPolicy Tests")
struct CountFlushPolicyTests {
    
    // MARK: - Initialization Tests
    
    @Test("when policy is created, then uses correct default flush count and should not flush initially")
    func testDefaultInitializationUsesCorrectValues() {
        let policy = CountFlushPolicy()
        
        #expect(policy.flushAt == Constants.flushEventCount.default)
        #expect(!policy.shouldFlush())
    }
    
    // MARK: - Invalid Value Handling Tests
    
    @Test("given invalid flushAt value, when policy is initialized, then falls back to default value", arguments: [
        Constants.flushEventCount.min - 1,
        Constants.flushEventCount.default,
        Constants.flushEventCount.max + 1,
        0,
        -10
    ])
    func testInvalidFlushAtValuesFallBackToDefault(_ flushAt: Int) {
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        #expect(policy.flushAt == Constants.flushEventCount.default)
    }
    
    // MARK: - Event Count and Flush Logic Tests
    
    @Test("given policy with threshold, when event count is below threshold, then shouldFlush returns false")
    func testShouldNotFlushBelowThreshold() {
        let flushAt = 5
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1..<flushAt {
            policy.updateEventCount()
        }
        
        #expect(!policy.shouldFlush())
    }
    
    @Test("given policy with threshold, when event count equals threshold, then shouldFlush returns true")
    func testShouldFlushAtExactThreshold() {
        let flushAt = 5
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1...flushAt {
            policy.updateEventCount()
        }
        
        #expect(policy.shouldFlush())
    }
    
    @Test("given policy with threshold, when event count exceeds threshold, then shouldFlush returns true")
    func testShouldFlushAboveThreshold() {
        let flushAt = 5
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1...(flushAt + 2) {
            policy.updateEventCount()
        }
        
        #expect(policy.shouldFlush())
    }
    
    // MARK: - Reset Functionality Tests
    
    @Test("given policy at threshold, when reset is called, then shouldFlush returns false")
    func testResetClearsEventCount() {
        let flushAt = 5
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1...flushAt {
            policy.updateEventCount()
        }
        
        policy.reset()
        #expect(!policy.shouldFlush())
    }
    
    @Test("given policy exceeding threshold, when reset is called, then clears count and can build up again")
    func testResetAfterExceedingThresholdAllowsRebuilding() {
        let flushAt = 3
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1...(flushAt + 5) {
            policy.updateEventCount()
        }
        #expect(policy.shouldFlush())
        
        policy.reset()
        #expect(!policy.shouldFlush())
        
        for _ in 1...flushAt {
            policy.updateEventCount()
        }
        #expect(policy.shouldFlush())
    }
    
    // MARK: - Progressive Event Count Tests
    
    @Test("given policy with threshold, when events are added progressively, then tracking works correctly")
    func testProgressiveEventCountTracking() {
        let flushAt = 10
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for i in 1..<flushAt {
            policy.updateEventCount()
            #expect(!policy.shouldFlush(), "Should not flush at event \(i)")
        }
        
        policy.updateEventCount()
        #expect(policy.shouldFlush(), "Should flush at event \(flushAt)")
    }
    
    
    @Test("given different valid flushAt values, when policies are tested, then all work correctly", arguments: [
        Constants.flushEventCount.min,
        Constants.flushEventCount.min + 5,
        Constants.flushEventCount.default,
        Constants.flushEventCount.max - 5,
        Constants.flushEventCount.max
    ])
    func testMultipleValidFlushAtValuesWorkCorrectly(_ flushAt: Int) {
        let policy = CountFlushPolicy(flushAt: flushAt)
        
        for _ in 1..<flushAt {
            policy.updateEventCount()
        }
        
        #expect(!policy.shouldFlush(), "Should not flush before threshold for flushAt: \(flushAt)")
        policy.updateEventCount()
        #expect(policy.shouldFlush(), "Should flush at threshold for flushAt: \(flushAt)")
    }
    
    @Test("given policy with operations, when various operations are performed, then flushAt property remains immutable")
    func testFlushAtPropertyRemainsImmutableAfterOperations() {
        let originalFlushAt = 15
        let policy = CountFlushPolicy(flushAt: originalFlushAt)
        let initialFlushAt = policy.flushAt
        
        policy.updateEventCount()
        policy.updateEventCount()
        policy.reset()
        for _ in 1...10 {
            policy.updateEventCount()
        }
        policy.reset()
        
        #expect(policy.flushAt == initialFlushAt, "flushAt should remain constant after operations")
        #expect(policy.flushAt == originalFlushAt, "flushAt should equal original value")
    }
}

