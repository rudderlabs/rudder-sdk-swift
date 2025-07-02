//
//  FrequencyFlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 02/01/25.
//

import Foundation

// MARK: - FrequencyFlushPolicy

/**
 A flush policy implementation that triggers periodic flushes based on a fixed time interval.

 The `FrequencyFlushPolicy` class uses a timer to periodically invoke the `flush` method on the associated `Analytics` instance. This ensures that events are flushed at regular intervals regardless of the number of events.

 - Features:
   - Configurable flush interval in milliseconds.
   - Automatic scheduling and cancellation of flush operations.
   - Ensures timer cleanup when the instance is deallocated.

 - Initialization:
   - The flush interval can be set during initialization and defaults to a predefined value.
   - The interval is clamped to a minimum threshold to avoid extremely short durations.

 - Usage:
   - Use `scheduleFlush(analytics:)` to start periodic flush scheduling with a specified `Analytics`.
   - Call `cancelScheduleFlush()` to stop the scheduled flush operations.

 - Thread Safety:
   - The timer operations are safely managed to avoid memory leaks and redundant scheduling.

 */
public final class FrequencyFlushPolicy: FlushPolicy {
    
    /// The timer responsible for periodic flush operations.
    private var flushTimer: Timer?

    /// The interval, in milliseconds, at which flush operations occur.
    private(set) var flushIntervalInMillis: UInt64

    /**
     Initializes a new `FrequencyFlushPolicy`.

     - Parameter flushIntervalInMillis: The time interval in milliseconds for triggering flushes. Defaults to `Constants.flushInterval.default`.
     */
    public init(flushIntervalInMillis: UInt64 = Constants.flushInterval.default) {
        self.flushIntervalInMillis = flushIntervalInMillis >= Constants.flushInterval.min ? flushIntervalInMillis : Constants.flushInterval.default
    }

    /**
     Schedules periodic flush operations using the provided `Analytics`.

     - Parameter analytics: The `Analytics` instance to invoke flush operations on.
     */
    func scheduleFlush(analytics: Analytics) {
        let millisecondsInSecond: TimeInterval = 1000.0
        
        self.flushTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(flushIntervalInMillis) / millisecondsInSecond,
            repeats: true,
            block: { [weak analytics] _ in
                analytics?.flush()
            }
        )
    }

    /**
     Cancels the scheduled periodic flush operations.
     */
    func cancelScheduleFlush() {
        flushTimer?.invalidate()
        flushTimer = nil
    }

    /**
     Deinitializes the `FrequencyFlushPolicy` and ensures the timer is invalidated.
     */
    deinit {
        cancelScheduleFlush()
    }
}
