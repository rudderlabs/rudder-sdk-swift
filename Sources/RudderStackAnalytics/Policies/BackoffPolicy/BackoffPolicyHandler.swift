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
final actor BackoffPolicyHandler: TypeIdentifiable {
    private let maxAttempts: Int
    private let coolOffPeriodMillis: Int
    private var currentAttempt: Int
    private var policy: BackoffPolicy
    private let logger: Logger

    init(logger: Logger, policy: BackoffPolicy = ExponentialBackoffPolicy(), coolOffPeriodMillis: Int = BackoffPolicyConstants.coolOffPeriodInMilliseconds) {
        self.maxAttempts = BackoffPolicyConstants.maxAttempts
        self.coolOffPeriodMillis = coolOffPeriodMillis
        self.policy = policy
        self.currentAttempt = 0
        self.logger = logger
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
        logger.verbose(log: "\(className): Max attempts reached. Entering cool-off period.")
        self.reset()
        logger.verbose(log: "\(className): Next attempt will be after \(BackoffPolicyHelper.formatMilliseconds(coolOffPeriodMillis)).")
        try? await BackoffPolicyHelper.sleep(milliseconds: coolOffPeriodMillis)
    }

    /**
     Applies the backoff strategy before the next retry attempt.
     */
    private func applyBackoff() async {
        let delay = self.policy.nextDelayInMilliseconds()
        logger.verbose(log: "\(className): Sleeping for \(BackoffPolicyHelper.formatMilliseconds(delay)) (attempt \(currentAttempt) of \(maxAttempts)).")
        try? await BackoffPolicyHelper.sleep(milliseconds: delay)
    }

    /**
     Resets the backoff policy to its initial state.
     This method should be called when the backoff policy needs to be restarted.
     */
    func reset() {
        logger.verbose(log: "\(className): Resetting retry attempts and backoff policy.")
        self.currentAttempt = 0
        self.policy.resetBackoff()
    }
}
