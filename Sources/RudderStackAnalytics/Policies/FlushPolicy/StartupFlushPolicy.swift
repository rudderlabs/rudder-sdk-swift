//
//  StartupFlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 02/01/25.
//

import Foundation

// MARK: - StartupFlushPolicy

/**
 A flush policy implementation that triggers a single flush operation at startup.

 The `StartupFlushPolicy` ensures that a flush operation is executed only once during the lifecycle of the application. After the initial flush, subsequent calls to `shouldFlush()` will return `false`.

 - Features:
   - Executes a one-time flush operation when the application starts or the policy is first evaluated.
   - Tracks the state to prevent multiple flushes.

 - Usage:
   - Instantiate the policy and use the `shouldFlush()` method to determine if a flush operation should occur.

 - Thread Safety:
   - This implementation is intended for single-threaded use cases, as no synchronization is applied.

 */
public final class StartupFlushPolicy: FlushPolicy {
    /// Tracks whether the flush has already been triggered.
    private var flushedAtStartup: Bool = false

    /// Initializes a new `StartupFlushPolicy`.
    public init() {
        /* Default implementation (no-op) */
    }

    /**
     Determines if a flush operation should occur.

     - Returns: `true` if this is the first call to `shouldFlush()`, `false` otherwise.
     - After the initial call, subsequent calls will always return `false`.
     */
    public func shouldFlush() -> Bool {
        guard !self.flushedAtStartup else { return false }
        self.flushedAtStartup = true
        return true
    }
}
