//
//  BackoffPolicyScheduler.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 29/08/25.
//

import Foundation

final actor BackoffPolicyScheduler {
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
        currentAttempt += 1
        
        if currentAttempt > maxAttempts {
            await applyCoolOffPeriod()
        } else {
            await applyBackoff()
        }
    }
    
    private func applyCoolOffPeriod() async {
        LoggerAnalytics.verbose(log: "Max attempts reached. Entering cool-off period for upload queue")
        self.reset()
        LoggerAnalytics.verbose(log: "Next attempt will be after \(coolOffSecs) secs")
        try? await self.sleep(seconds: coolOffSecs)
    }
    
    private func applyBackoff() async {
        let delay = policy.nextDelayInSeconds()
        LoggerAnalytics.verbose(log: "Sleeping for \(delay) secs (attempt \(currentAttempt) of \(maxAttempts))")
        try? await self.sleep(seconds: delay)
    }
    
    func reset() {
        LoggerAnalytics.verbose(log: "Resetting retry attempts and backoff policy")
        currentAttempt = 0
        policy.resetBackoff()
    }
}

extension BackoffPolicyScheduler {
    func sleep(seconds: Int) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
    }
}
