//
//  BackoffPolicy.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 29/08/25.
//

import Foundation

// MARK: - BackoffPolicy
/**
 Protocol representing a backoff policy for retrying operations.
 Implementations should provide a strategy for calculating the next delay
 and resetting the backoff state.
 */
protocol BackoffPolicy {
    /**
     Calculates the next delay in milliseconds based on the backoff policy.
     
     - Returns: The next delay in milliseconds.
     */
    func nextDelayInMilliseconds() -> Int
    
    /**
     Resets the backoff policy to its initial state.
     This method should be called when the backoff policy needs to be restarted.
     */
    func resetBackoff()
}

// MARK: - BackoffPolicyConstants

/**
 A struct containing constants used in backoff policies.
 */
struct BackoffPolicyConstants {

    private init() {
        /* Default implementation (no-op) */
    }

    static let maxAttempts = 5
    static let coolOffPeriodInMilliseconds = 1800000 // 30 minutes
}
