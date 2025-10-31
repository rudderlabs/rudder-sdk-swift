//
//  ExponentialBackoffPolicyTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("ExponentialBackoffPolicy Tests")
class ExponentialBackoffPolicyTests {
    var backoffPolicy: ExponentialBackoffPolicy
    
    init() {
        self.backoffPolicy = ExponentialBackoffPolicy()
    }
    
    @Test("given new exponential backoff policy, when requesting first delay, then returns delay within expected range")
    func testInitialDelay() {
        let firstDelay = backoffPolicy.nextDelayInMilliseconds()
        
        // First delay: minDelay (3000) + jitter (0 to 2999)
        #expect(firstDelay >= ExponentialBackoffConstants.minDelayInMillis, "Delay should be at least minimum")
        #expect(firstDelay < ExponentialBackoffConstants.minDelayInMillis * 2, "Delay should not exceed twice minimum")
    }
    
    @Test("given exponential backoff policy, when requesting multiple delays, then delays grow exponentially")
    func testExponentialGrowth() {
        let firstDelay = backoffPolicy.nextDelayInMilliseconds()
        let secondDelay = backoffPolicy.nextDelayInMilliseconds()
        let thirdDelay = backoffPolicy.nextDelayInMilliseconds()
        
        // First: 3000 + jitter (range: 3000-5999)
        #expect(firstDelay >= 3000, "First delay minimum check")
        #expect(firstDelay < 6000, "First delay maximum check")
        
        // Second: 6000 + jitter (range: 6000-11999)
        #expect(secondDelay >= 6000, "Second delay minimum check")
        #expect(secondDelay < 12000, "Second delay maximum check")
        
        // Third: 12000 + jitter (range: 12000-23999)
        #expect(thirdDelay >= 12000, "Third delay minimum check")
        #expect(thirdDelay < 24000, "Third delay maximum check")
    }
    
    @Test("given exponential backoff policy with attempts, when resetting, then delay returns to initial range")
    func testReset() {
        _ = backoffPolicy.nextDelayInMilliseconds() // Attempt 1
        _ = backoffPolicy.nextDelayInMilliseconds() // Attempt 2
        backoffPolicy.resetBackoff()
        let delayAfterReset = backoffPolicy.nextDelayInMilliseconds()
        
        #expect(delayAfterReset >= ExponentialBackoffConstants.minDelayInMillis, "Reset delay minimum")
        #expect(delayAfterReset < ExponentialBackoffConstants.minDelayInMillis * 2, "Reset delay maximum")
    }
    
    @Test("given custom minimum delay, when creating policy, then uses custom value")
    func testCustomMinDelay() {
        let customMinDelay = 1000
        let policy = ExponentialBackoffPolicy(minDelayInMillis: customMinDelay)
        let firstDelay = policy.nextDelayInMilliseconds()
        
        #expect(firstDelay >= customMinDelay, "Should respect custom minimum")
        #expect(firstDelay < customMinDelay * 2, "Should stay within jitter range")
    }
    
    @Test("given exponential backoff policy, when requesting delays multiple times, then demonstrates jitter variability")
    func testJitterVariability() {
        let policy = ExponentialBackoffPolicy(minDelayInMillis: 1000)
        
        policy.resetBackoff()
        let delay1 = policy.nextDelayInMilliseconds()
        
        policy.resetBackoff()
        let delay2 = policy.nextDelayInMilliseconds()
        
        policy.resetBackoff()
        let delay3 = policy.nextDelayInMilliseconds()
        
        let delays = [delay1, delay2, delay3]
        
        // All should be in the correct range
        for delay in delays {
            #expect(delay >= 1000, "All delays should be at least minimum")
            #expect(delay < 2000, "All delays should be within jitter range")
        }
        
        // At least some variation should exist
        let uniqueDelays = Set(delays)
        #expect(uniqueDelays.count > 1, "Jitter should create some variation in delays")
    }
    
    @Test("given exponential backoff policy, when reset multiple times, then each reset works correctly")
    func testMultipleResets() {
        // First cycle
        _ = backoffPolicy.nextDelayInMilliseconds()
        _ = backoffPolicy.nextDelayInMilliseconds()
        backoffPolicy.resetBackoff()
        let firstResetDelay = backoffPolicy.nextDelayInMilliseconds()
        
        // Second cycle
        _ = backoffPolicy.nextDelayInMilliseconds()
        backoffPolicy.resetBackoff()
        let secondResetDelay = backoffPolicy.nextDelayInMilliseconds()
        
        #expect(firstResetDelay >= ExponentialBackoffConstants.minDelayInMillis, "First reset minimum")
        #expect(firstResetDelay < ExponentialBackoffConstants.minDelayInMillis * 2, "First reset maximum")
        
        #expect(secondResetDelay >= ExponentialBackoffConstants.minDelayInMillis, "Second reset minimum")
        #expect(secondResetDelay < ExponentialBackoffConstants.minDelayInMillis * 2, "Second reset maximum")
    }
}
