//
//  FlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 29/10/24.
//

import Foundation

public protocol FlushPolicy {
    func shouldFlush() -> Bool
}

extension FlushPolicy {
    public func shouldFlush() -> Bool { false }
}

public final class CountFlushPolicy: FlushPolicy {
    private var flushCount: Int
    @Synchronized private var eventCount: Int = 0
    
    init(flushCount: Int = FlushEventCount.default.rawValue) {
        self.flushCount = min(FlushEventCount.max.rawValue, max(flushCount, FlushEventCount.min.rawValue))
    }
    
    public func updateEventCount() {
        self.eventCount += 1
    }
    
    public func shouldFlush() -> Bool {
        return self.eventCount >= self.flushCount
    }
    
    public func reset() {
        self.eventCount = 0
    }
}

public final class FrequencyFlushPolicy: FlushPolicy {
    private var analytics: AnalyticsClient?
    private var flushIntervalInMillis: Int
    private var flushTimer: Timer?
    
    public init(flushIntervalInMillis: Int = FlushInterval.default.rawValue) {
        self.flushIntervalInMillis = max(flushIntervalInMillis, FlushInterval.min.rawValue)
    }
    
    public func scheduleFlush(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.flushTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(flushIntervalInMillis) / 1000.0, repeats: true, block: { [weak analytics] _ in
            SerializedQueue.perform {
                analytics?.flush()
            }
        })
    }
    
    public func cancelScheduleFlush() {
        flushTimer?.invalidate()
        flushTimer = nil
    }
    
    deinit {
        cancelScheduleFlush()
    }
}

public final class StartupFlushPolicy: FlushPolicy {
    private var flushedAtStartup: Bool = false
    
    public func shouldFlush() -> Bool {
        guard !self.flushedAtStartup else { return false }
        self.flushedAtStartup = true
        return true
    }
}
