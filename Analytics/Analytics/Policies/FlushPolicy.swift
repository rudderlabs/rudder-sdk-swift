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
