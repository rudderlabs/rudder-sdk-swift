//
//  ExponentialBackoffPolicy.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 29/08/25.
//

import Foundation

// MARK: - ExponentialBackoffPolicy
/**
 Implements an exponential backoff with jitter for retries.
 Delay is calculated as: delay = interval * base^attempt,
 then adjusted with random jitter to prevent synchronized retries.
 */
final class ExponentialBackoffPolicy: BackoffPolicy {
    
    private var minDelayInSecs: Int
    private var base: Double
    private var attempt: Int
    
    /**
     Initializes the exponential backoff policy with configurable parameters.
     */
    init() {
        self.minDelayInSecs = ExponentialBackoffConstants.minDelayInSecs
        self.base = ExponentialBackoffConstants.defaultBase
        self.attempt = 0
    }
    
    /**
     Calculates the next delay in seconds based on the exponential backoff policy.
     
     - Returns: The next delay in seconds with jitter applied.
     */
    func nextDelayInSeconds() -> Int {
        let delayInSeconds = Int(Double(minDelayInSecs) * pow(base, Double(attempt)))
        attempt += 1
        
        let delayWithJitterInSeconds = withJitter(delayInSeconds)
        return delayWithJitterInSeconds
    }
    
    /**
     Applies random jitter to the delay to avoid synchronized retries.
     
     - Parameter delayInSeconds: The base delay in seconds
     - Returns: The delay with jitter applied
     */
    private func withJitter(_ delayInSeconds: Int) -> Int {
        let jitter = Int.random(in: 0..<delayInSeconds)
        return delayInSeconds + jitter
    }
    
    /**
     Resets the backoff policy to its initial state.
     This method should be called when the backoff policy needs to be restarted.
     */
    func resetBackoff() {
        attempt = 0
    }

}

// MARK: - ExponentialBackoffConstants
/**
 Constants for the exponential backoff policy.
 */
struct ExponentialBackoffConstants {
    
    private init() {
        /* Default implementation (no-op) */
    }
    
    static let defaultBase = 2.0
    static let minDelayInSecs = 3
}
