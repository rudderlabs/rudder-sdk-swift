//
//  BackoffPolicyHelperTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Foundation
import Testing
@testable import RudderStackAnalytics

@Suite("BackoffPolicyHelper Tests")
class BackoffPolicyHelperTests {
    
    @Test("given various millisecond values, when formatting, then returns correctly formatted strings")
    func testFormatMilliseconds() {
        // Test milliseconds only
        #expect(BackoffPolicyHelper.formatMilliseconds(500) == "500ms")
        #expect(BackoffPolicyHelper.formatMilliseconds(1) == "1ms")
        #expect(BackoffPolicyHelper.formatMilliseconds(999) == "999ms")
        
        // Test seconds
        #expect(BackoffPolicyHelper.formatMilliseconds(1000) == "1 sec")
        #expect(BackoffPolicyHelper.formatMilliseconds(2000) == "2 secs")
        #expect(BackoffPolicyHelper.formatMilliseconds(1500) == "1 sec 500ms")
        #expect(BackoffPolicyHelper.formatMilliseconds(5250) == "5 secs 250ms")
        
        // Test minutes
        #expect(BackoffPolicyHelper.formatMilliseconds(60000) == "1 min")
        #expect(BackoffPolicyHelper.formatMilliseconds(120000) == "2 mins")
        #expect(BackoffPolicyHelper.formatMilliseconds(61000) == "1 min 1 sec")
        #expect(BackoffPolicyHelper.formatMilliseconds(125000) == "2 mins 5 secs")
        #expect(BackoffPolicyHelper.formatMilliseconds(180500) == "3 mins 500ms")
    }
    
    @Test("given zero milliseconds, when calling sleep, then returns immediately")
    func testSleepWithZeroMilliseconds() async {
        let startTime = Date()
        try? await BackoffPolicyHelper.sleep(milliseconds: 0)
        let endTime = Date()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed < 0.01, "Should return almost immediately")
    }
    
    @Test("given positive milliseconds, when calling sleep, then sleeps for approximately specified duration")
    func testSleepWithPositiveMilliseconds() async {
        let startTime = Date()
        try? await BackoffPolicyHelper.sleep(milliseconds: 100)
        let endTime = Date()
        
        let elapsed = endTime.timeIntervalSince(startTime)
        #expect(elapsed >= 0.1, "Should sleep at least 100ms")
        #expect(elapsed < 0.15, "Should not exceed by much")
    }
}
