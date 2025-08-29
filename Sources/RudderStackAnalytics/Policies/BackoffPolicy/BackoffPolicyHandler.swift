//
//  BackoffPolicyHandler.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 29/08/25.
//

import Foundation

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
    
    func waitWithBackoff() async {
        self.currentAttempt += 1
        currentAttempt > maxAttempts ? await applyCoolOffPeriod() : await applyBackoff()
    }
    
    private func applyCoolOffPeriod() async {
        LoggerAnalytics.verbose(log: "Max attempts reached. Entering cool-off period.")
        self.reset()
        LoggerAnalytics.verbose(log: "Next attempt will be after \(formatSeconds(coolOffSecs)).")
        try? await self.sleep(seconds: coolOffSecs)
    }
    
    private func applyBackoff() async {
        let delay = self.policy.nextDelayInSeconds()
        LoggerAnalytics.verbose(log: "Sleeping for \(formatSeconds(delay)) (attempt \(currentAttempt) of \(maxAttempts)).")
        try? await self.sleep(seconds: delay)
    }
    
    func reset() {
        LoggerAnalytics.verbose(log: "Resetting retry attempts and backoff policy.")
        self.currentAttempt = 0
        self.policy.resetBackoff()
    }
}

extension BackoffPolicyHandler {
    func sleep(seconds: Int) async throws {
        let nanosecondsPerSecond: UInt64 = 1_000_000_000
        try await Task.sleep(nanoseconds: UInt64(seconds) * nanosecondsPerSecond)
    }
    
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
