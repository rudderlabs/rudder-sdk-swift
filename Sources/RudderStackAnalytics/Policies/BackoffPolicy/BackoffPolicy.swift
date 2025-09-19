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

// MARK: - BackoffPolicyHelper
/**
 Helper struct providing utility functions for backoff policies.
 */
struct BackoffPolicyHelper {
    
    private init() {
        /* Default implementation (no-op) */
    }
    
    /**
     Sleeps for the specified number of milliseconds.
     */
    static func sleep(milliseconds: Int) async throws {
        let nanosecondsPerMillisecond: UInt64 = 1_000_000
        try await Task.sleep(nanoseconds: UInt64(milliseconds) * nanosecondsPerMillisecond)
    }
    
    /**
     Formats the given total milliseconds into a human-readable string.
     */
    static func formatMilliseconds(_ totalMilliseconds: Int) -> String {
        let millisecondsPerSecond = 1000
        let secondsPerMinute = 60
        
        let totalSeconds = totalMilliseconds / millisecondsPerSecond
        let milliseconds = totalMilliseconds % millisecondsPerSecond
        let minutes = totalSeconds / secondsPerMinute
        let seconds = totalSeconds % secondsPerMinute
        
        func unit(_ value: Int, _ label: String) -> String {
            value == 1 ? "\(value) \(label)" : "\(value) \(label)s"
        }
        
        if minutes > 0 {
            if seconds > 0 {
                return "\(unit(minutes, "min")) \(unit(seconds, "sec"))"
            } else {
                return unit(minutes, "min")
            }
        } else if seconds > 0 {
            if milliseconds > 0 {
                return "\(unit(seconds, "sec")) \(milliseconds)ms"
            } else {
                return unit(seconds, "sec")
            }
        } else {
            return "\(milliseconds)ms"
        }
    }
}
