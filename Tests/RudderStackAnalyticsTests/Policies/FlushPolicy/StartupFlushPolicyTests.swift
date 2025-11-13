//
//  StartupFlushPolicyTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 31/10/25.
//

import Testing
@testable import RudderStackAnalytics

@Suite("StartupFlushPolicy Tests")
struct StartupFlushPolicyTests {
    
    // MARK: - Basic Behavior Tests
    
    @Test("given new startup policy, when shouldFlush is called first time, then returns true")
    func testFirstCallReturnsTrue() {
        let policy = StartupFlushPolicy()
        
        #expect(policy.shouldFlush())
    }
    
    @Test("given startup policy after first shouldFlush, when shouldFlush is called multiple times, then always returns false")
    func testSubsequentCallsAlwaysReturnFalse() {
        let policy = StartupFlushPolicy()
        _ = policy.shouldFlush() // First call
        
        for callNumber in 1...5 {
            #expect(!policy.shouldFlush(), "Call \(callNumber + 1) should return false")
        }
    }
    
    // MARK: - Multiple Instance Tests
    
    @Test("given multiple startup policy instances, when each is called independently, then each behaves correctly")
    func testMultipleInstanceIndependence() {
        let policy1 = StartupFlushPolicy()
        let policy2 = StartupFlushPolicy()
        
        #expect(policy1.shouldFlush(), "Policy1 first call should return true")
        #expect(policy2.shouldFlush(), "Policy2 first call should return true")
        #expect(!policy1.shouldFlush(), "Policy1 second call should return false")
        #expect(!policy2.shouldFlush(), "Policy2 second call should return false")
    }
    
    // MARK: - Real-World Usage Tests
    
    @Test("given startup policy, when used in typical application startup sequence, then behaves as expected")
    func testTypicalApplicationStartupSequence() {
        let policy = StartupFlushPolicy()
        
        let shouldFlushAtStartup = policy.shouldFlush()
        
        #expect(shouldFlushAtStartup, "Should flush during application startup")
        
        let shouldFlushDuringRuntime1 = policy.shouldFlush()
        let shouldFlushDuringRuntime2 = policy.shouldFlush()
        
        #expect(!shouldFlushDuringRuntime1, "Should not flush during runtime check 1")
        #expect(!shouldFlushDuringRuntime2, "Should not flush during runtime check 2")
    }
}
