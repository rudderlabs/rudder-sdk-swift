//
//  BackoffPolicyHandlerTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("BackoffPolicyHandler Tests")
class BackoffPolicyHandlerTests {
    
    var mockPolicy: MockBackoffPolicy
    
    init() {
        mockPolicy = MockBackoffPolicy()
    }
    
    @Test("given backoff policy handler with mock policy, when calling reset, then resets underlying policy")
    func testReset() async {
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        await handler.reset()
        
        #expect(mockPolicy.resetBackoffCalled, "Reset should be called on policy")
    }
    
    @Test("given handler with attempts below max, when calling wait with backoff, then applies backoff delay")
    func testWaitWithBackoffBelowMaxAttempts() async {
        mockPolicy.delayToReturn = 50 // Short delay for testing
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        let startTime = Date()
        await handler.waitWithBackoff()
        let endTime = Date()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed >= 0.05, "Should wait at least 50ms")
        #expect(mockPolicy.nextDelayInMillisecondsCalled, "Should call next delay method")
    }
    
    @Test("given handler exceeding max attempts, when calling wait with backoff, then enters cool-off period")
    func testWaitWithBackoffExceedsMaxAttempts() async {
        mockPolicy.delayToReturn = 10 // Very short delay for testing
        let handler = BackoffPolicyHandler(policy: mockPolicy, coolOffPeriodMillis: 10)
        
        // Call waitWithBackoff 5 times to reach max attempts
        for _ in 1...BackoffPolicyConstants.maxAttempts {
            await handler.waitWithBackoff()
        }
        
        // Reset mock to track the next call
        mockPolicy.resetBackoffCalled = false
        
        // This should trigger cool-off period
        await handler.waitWithBackoff()
        
        #expect(mockPolicy.resetBackoffCalled, "Should reset policy during cool-off")
    }
    
    @Test("given backoff policy handler, when calling reset multiple times, then resets policy each time")
    func testMultipleResets() async {
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        await handler.reset()
        await handler.reset()
        await handler.reset()
        
        #expect(mockPolicy.resetBackoffCalled, "Should call reset on policy")
    }
    
    @Test("given handler with real policy, when calling wait and reset, then operations complete successfully")
    func testIntegrationWithRealPolicy() async {
        let policy = ExponentialBackoffPolicy(minDelayInMillis: 10) // Very short for testing
        let handler = BackoffPolicyHandler(policy: policy)
        
        let startTime = Date()
        await handler.waitWithBackoff()
        let endTime = Date()
        
        await handler.reset()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed >= 0.01, "Should wait at least 10ms")
        // Reset should complete without errors (no direct assertion needed)
    }
}

// MARK: - MockBackoffPolicy
final class MockBackoffPolicy: BackoffPolicy {
    var nextDelayInMillisecondsCalled = false
    var resetBackoffCalled = false
    var delayToReturn = 1000 // Default 1 second in milliseconds
    
    func nextDelayInMilliseconds() -> Int {
        nextDelayInMillisecondsCalled = true
        return delayToReturn
    }
    
    func resetBackoff() {
        resetBackoffCalled = true
    }
}
