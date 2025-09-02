//
//  BackoffPolicyHandler.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 29/08/25.
//

import Foundation

// MARK: - BackoffPolicyHandler
/**
 Actor is responsible for managing the backoff policy for retrying operations.
 */
final actor BackoffPolicyHandler {
    private let maxAttempts: Int
    private let coolOffPeriodMillis: Int
    private var currentAttempt: Int
    private var policy: BackoffPolicy
    
    init(policy: BackoffPolicy = ExponentialBackoffPolicy()) {
        self.maxAttempts = BackoffPolicyConstants.maxAttempts
        self.coolOffPeriodMillis = BackoffPolicyConstants.coolOffPeriodInMilliseconds
        self.policy = policy
        self.currentAttempt = 0
    }

    /**
     Applies backoff or cool-off period before the next retry attempt.
     */
    func waitWithBackoff() async {
        self.currentAttempt += 1
        currentAttempt > maxAttempts ? await applyCoolOffPeriod() : await applyBackoff()
    }

    /**
     Applies the cool-off period before the next retry attempt.
     */
    private func applyCoolOffPeriod() async {
        LoggerAnalytics.verbose(log: "Max attempts reached. Entering cool-off period.")
        self.reset()
        LoggerAnalytics.verbose(log: "Next attempt will be after \(formatMilliseconds(coolOffPeriodMillis)).")
        try? await self.sleep(milliseconds: coolOffPeriodMillis)
    }

    /**
     Applies the backoff strategy before the next retry attempt.
     */
    private func applyBackoff() async {
        let delay = self.policy.nextDelayInMilliseconds()
        LoggerAnalytics.verbose(log: "Sleeping for \(formatMilliseconds(delay)) (attempt \(currentAttempt) of \(maxAttempts)).")
        try? await self.sleep(milliseconds: delay)
    }

    /**
     Resets the backoff policy to its initial state.
     This method should be called when the backoff policy needs to be restarted.
     */
    func reset() {
        LoggerAnalytics.verbose(log: "Resetting retry attempts and backoff policy.")
        self.currentAttempt = 0
        self.policy.resetBackoff()
    }
}

// MARK: - Helpers
extension BackoffPolicyHandler {
    /**
     Sleeps for the specified number of milliseconds.
     */
    private func sleep(milliseconds: Int) async throws {
        let nanosecondsPerMillisecond: UInt64 = 1_000_000
        try await Task.sleep(nanoseconds: UInt64(milliseconds) * nanosecondsPerMillisecond)
    }

    /**
     Formats the given total milliseconds into a human-readable string.
     */
    private func formatMilliseconds(_ totalMilliseconds: Int) -> String {
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
