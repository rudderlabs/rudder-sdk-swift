//
//  CountFlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 02/01/25.
//

import Foundation

// MARK: - CountFlushPolicy
/**
 A concrete implementation of the `FlushPolicy` protocol that triggers a flush based on a specified count of events.

 The `CountFlushPolicy` class monitors the number of events and triggers a flush when the count reaches or exceeds a predefined threshold.

 - Features:
   - Configurable flush count threshold.
   - Thread-safe event count updates using synchronization.
   - Resettable event count.

 - Initialization:
   - Initialize with a custom flush count or use the default value.
   - The flush count is clamped between predefined minimum and maximum values.

 - Thread Safety:
   - Event count updates are synchronized to ensure thread-safe operations.

 - Usage:
   - Call `updateEventCount()` to increment the event count.
   - Use `shouldFlush()` to check if the flush condition is met.
   - Reset the count with `reset()` after a flush operation.
 */
public final class CountFlushPolicy: FlushPolicy {
    /// The maximum number of events before a flush is triggered.
    private(set) var flushAt: Int

    /// The current count of events, updated in a thread-safe manner.
    @Synchronized private var eventCount: Int = 0

    /**
     Initializes a new `CountFlushPolicy`.

     - Parameter flushAt: The number of events required to trigger a flush. Defaults to `Constants.flushEventCount.default`.     */
    public init(flushAt: Int = Constants.flushEventCount.default) {
        self.flushAt = (Constants.flushEventCount.min...Constants.flushEventCount.max).contains(flushAt) ? flushAt : Constants.flushEventCount.default
    }

    /**
     Increments the internal event count in a thread-safe manner.
     */
    func updateEventCount() {
        self.eventCount += 1
    }

    /**
     Checks if the flush condition is met based on the event count.

     - Returns: A `Bool` indicating whether the flush count has been reached or exceeded.
     */
    public func shouldFlush() -> Bool {
        return self.eventCount >= self.flushAt
    }

    /**
     Resets the internal event count to zero.
     */
    func reset() {
        self.eventCount = 0
    }
}
