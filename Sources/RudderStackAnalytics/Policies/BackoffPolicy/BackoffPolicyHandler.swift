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
    private let coolOffSecs: Int
    private var policy: BackoffPolicy
    private var currentAttempt: Int
    
    init() {
        self.maxAttempts = BackOffPolicyConstants.maxAttempts
        self.coolOffSecs = BackOffPolicyConstants.coolOffPeriodInSeconds
        self.policy = ExponentialBackoffPolicy()
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
        LoggerAnalytics.verbose(log: "Next attempt will be after \(formatSeconds(coolOffSecs)).")
        try? await self.sleep(seconds: coolOffSecs)
    }

    /**
     Applies the backoff strategy before the next retry attempt.
     */
    private func applyBackoff() async {
        let delay = self.policy.nextDelayInSeconds()
        LoggerAnalytics.verbose(log: "Sleeping for \(formatSeconds(delay)) (attempt \(currentAttempt) of \(maxAttempts)).")
        try? await self.sleep(seconds: delay)
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
     Sleeps for the specified number of seconds.
     */
    func sleep(seconds: Int) async throws {
        let nanosecondsPerSecond: UInt64 = 1_000_000_000
        try await Task.sleep(nanoseconds: UInt64(seconds) * nanosecondsPerSecond)
    }

    /**
     Formats the given total seconds into a human-readable string.
     */
    func formatSeconds(_ totalSeconds: Int) -> String {
        let secondsPerMinute = 60

        let minutes = totalSeconds / secondsPerMinute
        let seconds = totalSeconds % secondsPerMinute
        
        func unit(_ value: Int, _ label: String) -> String {
            value == 1 ? "\(value) \(label)" : "\(value) \(label)s"
        }
        
        if minutes > 0 && seconds > 0 {
            return "\(unit(minutes, "min")) \(unit(seconds, "sec"))"
        } else if minutes > 0 {
            return unit(minutes, "min")
        } else {
            return unit(seconds, "sec")
        }
    }
}
