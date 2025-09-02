//
//  BackoffPolicyTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 01/09/25.
//

import Foundation
import XCTest
@testable import RudderStackAnalytics

// MARK: - BackoffPolicyTests
final class BackoffPolicyTests: XCTestCase {
    
    private var backoffPolicy: ExponentialBackoffPolicy!
    private var backoffHandler: BackoffPolicyHandler!
    
    override func setUp() {
        super.setUp()
        backoffPolicy = ExponentialBackoffPolicy()
        backoffHandler = BackoffPolicyHandler(policy: backoffPolicy)
    }
    
    override func tearDown() {
        backoffPolicy = nil
        backoffHandler = nil
        super.tearDown()
    }
    
    // MARK: - ExponentialBackoffPolicy Tests
    
    func test_exponentialBackoffPolicy_initialState() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        let firstDelay = policy.nextDelayInMilliseconds()
        
        // Then
        // First delay should be between minDelayInMillis (3000) and minDelayInMillis * 2 (6000) due to jitter
        XCTAssertGreaterThanOrEqual(firstDelay, ExponentialBackoffConstants.minDelayInMillis)
        XCTAssertLessThan(firstDelay, ExponentialBackoffConstants.minDelayInMillis * 2)
    }
    
    func test_exponentialBackoffPolicy_exponentialGrowth() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        let firstDelay = policy.nextDelayInMilliseconds()
        let secondDelay = policy.nextDelayInMilliseconds()
        let thirdDelay = policy.nextDelayInMilliseconds()
        
        // Then
        // Each delay should generally increase exponentially (accounting for jitter)
        // First delay: 3000 * 2^0 = 3000 (+ jitter)
        // Second delay: 3000 * 2^1 = 6000 (+ jitter)
        // Third delay: 3000 * 2^2 = 12000 (+ jitter)
        XCTAssertGreaterThanOrEqual(firstDelay, 3000)
        XCTAssertGreaterThanOrEqual(secondDelay, 6000)
        XCTAssertGreaterThanOrEqual(thirdDelay, 12000)
        
        // Verify exponential growth pattern (base delay without jitter)
        XCTAssertLessThan(firstDelay, 6000)  // First delay should be less than base of second
        XCTAssertLessThan(secondDelay, 12000) // Second delay should be less than base of third
    }
    
    func test_exponentialBackoffPolicy_resetBackoff() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        _ = policy.nextDelayInMilliseconds() // Increment attempt count
        _ = policy.nextDelayInMilliseconds() // Increment attempt count again
        policy.resetBackoff() // Reset to initial state
        let delayAfterReset = policy.nextDelayInMilliseconds()
        
        // Then
        // After reset, delay should be back to initial range
        XCTAssertGreaterThanOrEqual(delayAfterReset, ExponentialBackoffConstants.minDelayInMillis)
        XCTAssertLessThan(delayAfterReset, ExponentialBackoffConstants.minDelayInMillis * 2)
    }
    
    // MARK: - BackoffPolicyHandler Tests
    
    func test_backoffPolicyHandler_reset() async {
        // Given
        let mockPolicy = MockBackoffPolicy()
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        // When
        await handler.reset()
        
        // Then
        XCTAssertTrue(mockPolicy.resetBackoffCalled)
    }
    
    func test_backoffPolicyHandler_waitWithBackoff_appliesDelay() async {
        // Given
        let mockPolicy = MockBackoffPolicy()
        mockPolicy.delayToReturn = 1000 // Short delay for testing (1 second in milliseconds)
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        // When
        let startTime = Date()
        await handler.waitWithBackoff()
        let endTime = Date()
        
        // Then
        let elapsedTime = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsedTime, 1.0) // Should wait at least 1 second
        XCTAssertTrue(mockPolicy.nextDelayInMillisecondsCalled)
    }
    
    // MARK: - Edge Cases and Integration Tests
    
    func test_exponentialBackoffPolicy_multipleResets() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        _ = policy.nextDelayInMilliseconds() // First call
        _ = policy.nextDelayInMilliseconds() // Second call
        policy.resetBackoff() // First reset
        let delayAfterFirstReset = policy.nextDelayInMilliseconds()
        
        _ = policy.nextDelayInMilliseconds() // Another call
        policy.resetBackoff() // Second reset
        let delayAfterSecondReset = policy.nextDelayInMilliseconds()
        
        // Then
        // Both delays after reset should be in the initial range
        XCTAssertGreaterThanOrEqual(delayAfterFirstReset, ExponentialBackoffConstants.minDelayInMillis)
        XCTAssertLessThan(delayAfterFirstReset, ExponentialBackoffConstants.minDelayInMillis * 2)
        
        XCTAssertGreaterThanOrEqual(delayAfterSecondReset, ExponentialBackoffConstants.minDelayInMillis)
        XCTAssertLessThan(delayAfterSecondReset, ExponentialBackoffConstants.minDelayInMillis * 2)
    }
}

// MARK: - Mock Classes for Testing

final class MockBackoffPolicy: BackoffPolicy {
    var nextDelayInMillisecondsCalled = false
    var resetBackoffCalled = false
    var delayToReturn = 3000 // Default 3 seconds in milliseconds
    
    func nextDelayInMilliseconds() -> Int {
        nextDelayInMillisecondsCalled = true
        return delayToReturn
    }
    
    func resetBackoff() {
        resetBackoffCalled = true
    }
}

