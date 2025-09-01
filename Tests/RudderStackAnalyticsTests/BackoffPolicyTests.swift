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
        let firstDelay = policy.nextDelayInSeconds()
        
        // Then
        // First delay should be between minDelayInSecs (3) and minDelayInSecs * 2 (6) due to jitter
        XCTAssertGreaterThanOrEqual(firstDelay, ExponentialBackoffConstants.minDelayInSecs)
        XCTAssertLessThan(firstDelay, ExponentialBackoffConstants.minDelayInSecs * 2)
    }
    
    func test_exponentialBackoffPolicy_exponentialGrowth() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        let firstDelay = policy.nextDelayInSeconds()
        let secondDelay = policy.nextDelayInSeconds()
        let thirdDelay = policy.nextDelayInSeconds()
        
        // Then
        // Each delay should generally increase exponentially (accounting for jitter)
        // First delay: 3 * 2^0 = 3 (+ jitter)
        // Second delay: 3 * 2^1 = 6 (+ jitter)
        // Third delay: 3 * 2^2 = 12 (+ jitter)
        XCTAssertGreaterThanOrEqual(firstDelay, 3)
        XCTAssertGreaterThanOrEqual(secondDelay, 6)
        XCTAssertGreaterThanOrEqual(thirdDelay, 12)
        
        // Verify exponential growth pattern (base delay without jitter)
        XCTAssertLessThan(firstDelay, 6)  // First delay should be less than base of second
        XCTAssertLessThan(secondDelay, 12) // Second delay should be less than base of third
    }
    
    func test_exponentialBackoffPolicy_resetBackoff() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        _ = policy.nextDelayInSeconds() // Increment attempt count
        _ = policy.nextDelayInSeconds() // Increment attempt count again
        policy.resetBackoff() // Reset to initial state
        let delayAfterReset = policy.nextDelayInSeconds()
        
        // Then
        // After reset, delay should be back to initial range
        XCTAssertGreaterThanOrEqual(delayAfterReset, ExponentialBackoffConstants.minDelayInSecs)
        XCTAssertLessThan(delayAfterReset, ExponentialBackoffConstants.minDelayInSecs * 2)
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
        mockPolicy.delayToReturn = 1 // Short delay for testing
        let handler = BackoffPolicyHandler(policy: mockPolicy)
        
        // When
        let startTime = Date()
        await handler.waitWithBackoff()
        let endTime = Date()
        
        // Then
        let elapsedTime = endTime.timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsedTime, 1.0) // Should wait at least 1 second
        XCTAssertTrue(mockPolicy.nextDelayInSecondsCalled)
    }
    
    // MARK: - Edge Cases and Integration Tests
    
    func test_exponentialBackoffPolicy_multipleResets() {
        // Given
        let policy = ExponentialBackoffPolicy()
        
        // When
        _ = policy.nextDelayInSeconds() // First call
        _ = policy.nextDelayInSeconds() // Second call
        policy.resetBackoff() // First reset
        let delayAfterFirstReset = policy.nextDelayInSeconds()
        
        _ = policy.nextDelayInSeconds() // Another call
        policy.resetBackoff() // Second reset
        let delayAfterSecondReset = policy.nextDelayInSeconds()
        
        // Then
        // Both delays after reset should be in the initial range
        XCTAssertGreaterThanOrEqual(delayAfterFirstReset, ExponentialBackoffConstants.minDelayInSecs)
        XCTAssertLessThan(delayAfterFirstReset, ExponentialBackoffConstants.minDelayInSecs * 2)
        
        XCTAssertGreaterThanOrEqual(delayAfterSecondReset, ExponentialBackoffConstants.minDelayInSecs)
        XCTAssertLessThan(delayAfterSecondReset, ExponentialBackoffConstants.minDelayInSecs * 2)
    }
}

// MARK: - Mock Classes for Testing

final class MockBackoffPolicy: BackoffPolicy {
    var nextDelayInSecondsCalled = false
    var resetBackoffCalled = false
    var delayToReturn = 3
    
    func nextDelayInSeconds() -> Int {
        nextDelayInSecondsCalled = true
        return delayToReturn
    }
    
    func resetBackoff() {
        resetBackoffCalled = true
    }
}

