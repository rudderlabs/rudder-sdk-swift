//
//  BackOffPolicy.swift
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
     Calculates the next delay in seconds based on the backoff policy.
     
     - Returns: The next delay in seconds.
     */
    func nextDelayInSeconds() -> Int
    
    /**
     Resets the backoff policy to its initial state.
     This method should be called when the backoff policy needs to be restarted.
     */
    func resetBackoff()
}

// MARK: - BackOffPolicyConstants

/**
 A struct containing constants used in backoff policies.
 */
struct BackOffPolicyConstants {

    private init() {
        /* Default implementation (no-op) */
    }

    static let maxAttempts = 5
    static let coolOffPeriodInSeconds = 1800 // 30 minutes
}
