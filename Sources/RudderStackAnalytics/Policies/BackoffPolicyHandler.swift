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
        LoggerAnalytics.verbose(log: "Next attempt will be after \(coolOffSecs) secs")
        try? await self.sleep(seconds: coolOffSecs)
    }
    
    private func applyBackoff() async {
        let delay = self.policy.nextDelayInSeconds()
        LoggerAnalytics.verbose(log: "Sleeping for \(delay) secs (attempt \(currentAttempt) of \(maxAttempts))")
        try? await self.sleep(seconds: delay)
    }
    
    func reset() {
        LoggerAnalytics.verbose(log: "Resetting retry attempts and backoff policy")
        self.currentAttempt = 0
        self.policy.resetBackoff()
    }
}

extension BackoffPolicyHandler {
    func sleep(seconds: Int) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
    }
}
