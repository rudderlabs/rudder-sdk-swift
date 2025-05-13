//
//  FlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 29/10/24.
//

import Foundation

// MARK: - FlushPolicy
/**
 A protocol defining a policy for determining when a flush operation should occur.

 The `FlushPolicy` protocol is designed to be implemented by custom classes or structs that define specific conditions under which a flush operation should be triggered. These conditions can vary based on business rules or operational requirements.

 - Features:
   - Provides a single method `shouldFlush()` to evaluate the flush condition.
   - Includes a default implementation that always returns `false`.

 - Usage:
   Implement this protocol and override the `shouldFlush()` method to define custom flush logic.

 - Default Behavior:
   The default implementation of `shouldFlush()` in the protocol extension returns `false`, indicating that no flush should occur unless explicitly overridden.
 */
@objc
public protocol FlushPolicy {
    /**
     Determines whether a flush operation should be triggered on user's call.

     - Returns: A `Bool` indicating if the flush condition is met (`true`) or not (`false`).
     */
    @objc
    func shouldFlush() -> Bool
}

// MARK: - FlushPolicyFacade

/**
 A facade class for managing multiple flush policies.

 The `FlushPolicyFacade` coordinates the behavior of various flush policies (`StartupFlushPolicy`, `CountFlushPolicy`, and `FrequencyFlushPolicy`) within the analytics system. It provides a unified interface to interact with these policies, enabling easier management and integration.

 - Features:
   - Aggregates and manages multiple flush policies.
   - Evaluates conditions for triggering a flush based on active policies.
   - Handles scheduling and cancellation for frequency-based policies.
   - Updates and resets event counts for count-based policies.

 - Usage:
   - Instantiate the facade with an `AnalyticsClient`.
   - Use the provided methods to evaluate flush conditions or manage scheduled flushes.

 - Dependencies:
   - Requires `AnalyticsClient` to access configuration and active flush policies.

 */
final class FlushPolicyFacade {
    /// The analytics client used for accessing flush policy configurations.
    private var analytics: AnalyticsClient

    /**
     Initializes a new instance of `FlushPolicyFacade`.

     - Parameter analytics: The `AnalyticsClient` instance for accessing flush configurations.
     */
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
    }

    /// The list of currently active flush policies.
    var activePolicies: [FlushPolicy] {
        return self.analytics.configuration.flushPolicies
    }

    /**
     Determines whether a flush should occur based on the active policies.

     - Returns: `true` if any active policy indicates that a flush should occur, otherwise `false`.
     - Includes checks for `StartupFlushPolicy` and `CountFlushPolicy`.
     */
    func shouldFlush() -> Bool {
        return self.activePolicies.contains { ($0 is StartupFlushPolicy || $0 is CountFlushPolicy) && $0.shouldFlush() }
    }

    /// Starts scheduled flushes for frequency-based policies.
    func startSchedule() {
        self.activePolicies
            .compactMap { $0 as? FrequencyFlushPolicy }
            .forEach { $0.scheduleFlush(analytics: self.analytics) }
    }

    /// Cancels scheduled flushes for frequency-based policies.
    func cancelSchedule() {
        self.activePolicies
            .compactMap { $0 as? FrequencyFlushPolicy }
            .forEach { $0.cancelScheduleFlush() }
    }

    /// Updates the event count for count-based policies.
    func updateCount() {
        self.activePolicies
            .compactMap { $0 as? CountFlushPolicy }
            .forEach { $0.updateEventCount() }
    }

    /// Resets the event count for count-based policies.
    func resetCount() {
        self.activePolicies
            .compactMap { $0 as? CountFlushPolicy }
            .forEach { $0.reset() }
    }
}
