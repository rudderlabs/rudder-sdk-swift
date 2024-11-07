//
//  FlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 29/10/24.
//

import Foundation

// MARK: - FlushPolicy
public protocol FlushPolicy {
    func shouldFlush() -> Bool
}

extension FlushPolicy {
    public func shouldFlush() -> Bool { false }
}

// MARK: - CountFlushPolicy

public final class CountFlushPolicy: FlushPolicy {
    private(set) var flushCount: Int
    @Synchronized private var eventCount: Int = 0
    
    public init(flushCount: Int = FlushEventCount.default.rawValue) {
        self.flushCount = min(FlushEventCount.max.rawValue, max(flushCount, FlushEventCount.min.rawValue))
    }
    
    func updateEventCount() {
        self.eventCount += 1
    }
    
    public func shouldFlush() -> Bool {
        return self.eventCount >= self.flushCount
    }
    
    func reset() {
        self.eventCount = 0
    }
}

// MARK: - FrequencyFlushPolicy

public final class FrequencyFlushPolicy: FlushPolicy {
    private var analytics: AnalyticsClient?
    private var flushTimer: Timer?
    private(set) var flushIntervalInMillis: Double
    
    public init(flushIntervalInMillis: Double = FlushInterval.default.rawValue) {
        self.flushIntervalInMillis = max(flushIntervalInMillis, FlushInterval.min.rawValue)
    }
    
    func scheduleFlush(analytics: AnalyticsClient) {
        self.analytics = analytics
        self.flushTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(flushIntervalInMillis) / 1000.0, repeats: true, block: { [weak analytics] _ in
            analytics?.flush()
        })
    }
    
    func cancelScheduleFlush() {
        flushTimer?.invalidate()
        flushTimer = nil
    }
    
    deinit {
        cancelScheduleFlush()
    }
}

// MARK: - StartupFlushPolicy

public final class StartupFlushPolicy: FlushPolicy {
    private var flushedAtStartup: Bool = false
    
    public init() {}
    
    public func shouldFlush() -> Bool {
        guard !self.flushedAtStartup else { return false }
        self.flushedAtStartup = true
        return true
    }
}

// MARK: - FlushPolicyFacade
final class FlushPolicyFacade {
    private var analytics: AnalyticsClient
    
    init(analytics: AnalyticsClient) {
        self.analytics = analytics
    }
    
    var activePolicies: [FlushPolicy] {
        return self.analytics.configuration.flushPolicies
    }
    
    func shouldFlush() -> Bool {
        return self.activePolicies.contains { ($0 is StartupFlushPolicy || $0 is CountFlushPolicy) && $0.shouldFlush() }
    }
    
    func startSchedule() {
        self.activePolicies.compactMap { $0 as? FrequencyFlushPolicy }.forEach { $0.scheduleFlush(analytics: self.analytics) }
    }
    
    func cancelSchedule() {
        self.activePolicies.compactMap { $0 as? FrequencyFlushPolicy }.forEach { $0.cancelScheduleFlush() }
    }
    
    func updateCount() {
        self.activePolicies.compactMap { $0 as? CountFlushPolicy }.forEach { $0.updateEventCount() }
    }
    
    func resetCount() {
        self.activePolicies.compactMap { $0 as? CountFlushPolicy }.forEach { $0.reset() }
    }
}
