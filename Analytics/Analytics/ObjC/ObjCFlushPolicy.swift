//
//  ObjCFlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

// MARK: - ObjCFlushPolicy
/**
 A marker protocol to represent a flush policy for use in Objective-C.

 Flush policies define conditions under which queued events should be flushed (sent).
 */
@objc(RSAFlushPolicy)
public protocol ObjCFlushPolicy {
    /* Default implementation (no-op) */
}

// MARK: - ObjcStartupFlushPolicy
/**
 A flush policy that triggers a flush as soon as the app starts.

 This is a wrapper around the `StartupFlushPolicy` for use in Objective-C.
 */
@objc(RSAStartupFlushPolicy)
public final class ObjcStartupFlushPolicy: NSObject, ObjCFlushPolicy {

    /** The wrapped `StartupFlushPolicy` instance. */
    let flushPolicy: StartupFlushPolicy

    /**
     Initializes a `StartupFlushPolicy` with default behavior.
     */
    @objc
    public override init() {
        self.flushPolicy = StartupFlushPolicy()
        super.init()
    }

    /**
     Initializes the wrapper with an existing `StartupFlushPolicy`.

     - Parameter policy: An instance of `StartupFlushPolicy` to wrap.
     */
    public init(policy: StartupFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}

// MARK: - ObjcCountFlushPolicy
/**
 A flush policy that triggers a flush when a specific number of events are queued.

 This is a wrapper around the `CountFlushPolicy` for use in Objective-C.
 */
@objc(RSACountFlushPolicy)
public final class ObjcCountFlushPolicy: NSObject, ObjCFlushPolicy {

    /** The wrapped `CountFlushPolicy` instance. */
    let flushPolicy: CountFlushPolicy

    /**
     Initializes the flush policy with a custom event count threshold.

     - Parameter count: The number of events after which a flush should occur.
     */
    @objc
    public init(count: Int) {
        self.flushPolicy = CountFlushPolicy(flushCount: count)
        super.init()
    }

    /**
     Initializes the flush policy with the default event count threshold.
     */
    @objc
    public convenience override init() {
        self.init(count: Constants.flushEventCount.default)
    }

    /**
     Initializes the wrapper with an existing `CountFlushPolicy`.

     - Parameter policy: An instance of `CountFlushPolicy` to wrap.
     */
    public init(policy: CountFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}

// MARK: - ObjcFrequencyFlushPolicy
/**
 A flush policy that triggers a flush at regular time intervals.

 This is a wrapper around the `FrequencyFlushPolicy` for use in Objective-C.
 */
@objc(RSAFrequencyFlushPolicy)
public final class ObjcFrequencyFlushPolicy: NSObject, ObjCFlushPolicy {

    /** The wrapped `FrequencyFlushPolicy` instance. */
    let flushPolicy: FrequencyFlushPolicy

    /**
     Initializes the flush policy with a custom time interval.

     - Parameter flushIntervalInMillis: The time interval in milliseconds between flushes.
     */
    @objc
    public init(flushIntervalInMillis: UInt64) {
        self.flushPolicy = FrequencyFlushPolicy(flushIntervalInMillis: flushIntervalInMillis)
        super.init()
    }

    /**
     Initializes the flush policy with the default time interval.
     */
    @objc
    public convenience override init() {
        self.init(flushIntervalInMillis: Constants.flushInterval.default)
    }

    /**
     Initializes the wrapper with an existing `FrequencyFlushPolicy`.

     - Parameter policy: An instance of `FrequencyFlushPolicy` to wrap.
     */
    public init(policy: FrequencyFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}
