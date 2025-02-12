//
//  FlushPolicyModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 05/11/24.
//

import XCTest
@testable import Analytics

final class CountFlushPolicyTests: XCTestCase {
    
    func test_defaultShouldFlush() {
        given("CountFlushPolicy with a flush count of 5") {
            let policy = CountFlushPolicy(flushCount: 5)
            
            then("initially returns false..") {
                XCTAssertFalse(policy.shouldFlush())
            }
        }
    }
    
    func test_shouldFlushAfterReachingFlushCount() {
        given("CountFlushPolicy with a flush count of 5") {
            let policy = CountFlushPolicy(flushCount: 5)
            
            when("flush count not reached the limit..") {
                for _ in 1...4 {
                    policy.updateEventCount()
                }
                
                then("returns false..") {
                    XCTAssertFalse(policy.shouldFlush())
                }
            }
            
            when("flush count reached the limit..") {
                policy.updateEventCount()
                
                then("returns true..") {
                    XCTAssertTrue(policy.shouldFlush())
                }
            }
        }
    }
    
    func test_resetCount() {
        given("CountFlushPolicy with a flush count of 5") {
            let policy = CountFlushPolicy(flushCount: 5)
            
            when("flush count reached the limit..") {
                for _ in 1...5 {
                    policy.updateEventCount()
                }
                
                then("returns true..") {
                    XCTAssertTrue(policy.shouldFlush())
                }
            }
            
            when("flush count resets...") {
                policy.reset()
                
                then("returns false..") {
                    XCTAssertFalse(policy.shouldFlush())
                }
            }
        }
    }
    
    func test_flushCountRange() {
        given("Flush count range...") {
            let minimum = RSConstants.Flush.EventCount.min
            let maximum = RSConstants.Flush.EventCount.max
            let defaultValue = RSConstants.Flush.EventCount.default
            
            when("without passing any flush count value...") {
                let policy = CountFlushPolicy()
                
                for _ in 1...defaultValue {
                    policy.updateEventCount()
                }
                
                then("returns true..") {
                    XCTAssertTrue(policy.shouldFlush())
                }
            }
            
            when("pass the minimum flush count...") {
                let policy = CountFlushPolicy(flushCount: minimum)
                
                for _ in 1..<minimum {
                    policy.updateEventCount()
                }
                
                then("returns false..") {
                    XCTAssertFalse(policy.shouldFlush())
                }
                
                when("flush count reached the limit..") {
                    policy.updateEventCount()
                    
                    then("returns true..") {
                        XCTAssertTrue(policy.shouldFlush())
                    }
                }
            }
            
            when("pass the maximum flush count...") {
                let policy = CountFlushPolicy(flushCount: maximum)
                
                for _ in 1..<maximum {
                    policy.updateEventCount()
                }
                
                then("returns false..") {
                    XCTAssertFalse(policy.shouldFlush())
                }
                
                when("flush count reached the limit..") {
                    policy.updateEventCount()
                    
                    then("returns true..") {
                        XCTAssertTrue(policy.shouldFlush())
                    }
                }
            }
        }
    }
}

final class FrequencyFlushPolicyTests: XCTestCase {
    
    func test_validFlushFrequency() {
        given("FrequentlyFlushPolicy with 0.5sec flush interval... ") {
            let mills = MockHelper.milliseconds(from: 0.5)
            let policy = FrequencyFlushPolicy(flushIntervalInMillis: mills)
            
            when("initiate the shedule...") {
                let client = MockAnalyticsClient()
                policy.scheduleFlush(analytics: client)
                
                RunLoop.current.run(until: Date(timeIntervalSinceNow: MockHelper.seconds(from: mills * 2)))
                then("returns true..") {
                    XCTAssertTrue(client.isFlushed)
                    policy.cancelScheduleFlush()
                }
            }
        }
    }
    
    func test_invalidFlushFrequency() {
        given("FrequentlyFlushPolicy with -1.5sec flush interval... ") {
            let mills = MockHelper.milliseconds(from: -1.5)
            
            when("preare the policy...") {
                let policy = FrequencyFlushPolicy(flushIntervalInMillis: mills)
                let minimum = RSConstants.Flush.Interval.min
                
                then("sets the flush interval to minimum..") {
                    XCTAssertTrue(policy.flushIntervalInMillis == minimum)
                }
            }
        }
    }
    
    func test_defaultFlushFrequency() {
        given("FrequencyFlushPolicy with default flush interval... ") {
            let policy = FrequencyFlushPolicy()
            let defaultValue = RSConstants.Flush.Interval.default
            
            then("sets the flush interval to default..") {
                XCTAssertTrue(policy.flushIntervalInMillis == defaultValue)
            }
        }
    }
}

final class startupFlushPolicyTests: XCTestCase {
    
    func test_startupFlushPolicy() {
        given("Startup Flush Policy..") {
            let policy = StartupFlushPolicy()
            
            then("Should flush on startup..") {
                XCTAssertTrue(policy.shouldFlush())
            }
            
            then("Should not flush on shutdown..") {
                XCTAssertFalse(policy.shouldFlush())
            }
        }
    }
}
