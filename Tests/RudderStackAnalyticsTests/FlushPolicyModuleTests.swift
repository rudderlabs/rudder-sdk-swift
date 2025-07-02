//
//  FlushPolicyModuleTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 05/11/24.
//

import XCTest
@testable import RudderStackAnalytics

final class CountFlushPolicyTests: XCTestCase {
    
    func test_defaultShouldFlush() {
        given("CountFlushPolicy with a flush count of 5") {
            let policy = CountFlushPolicy(flushAt: 5)
            
            then("initially returns false..") {
                XCTAssertFalse(policy.shouldFlush())
            }
        }
    }
    
    func test_shouldFlushAfterReachingFlushCount() {
        given("CountFlushPolicy with a flush count of 5") {
            let policy = CountFlushPolicy(flushAt: 5)
            
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
            let policy = CountFlushPolicy(flushAt: 5)
            
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
            let minimum = Constants.flushEventCount.min
            let maximum = Constants.flushEventCount.max
            let defaultValue = Constants.flushEventCount.default
            
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
                let policy = CountFlushPolicy(flushAt: minimum)
                
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
                let policy = CountFlushPolicy(flushAt: maximum)
                
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
    
    func test_flushCountInvalidValues() {
        given("Invalid flush count values...") {
            let defaultValue = Constants.flushEventCount.default
            
            when("pass a value below minimum...") {
                let belowMinimum = Constants.flushEventCount.min - 1
                let policy = CountFlushPolicy(flushAt: belowMinimum)
                
                then("should use default value instead") {
                    XCTAssertEqual(policy.flushAt, defaultValue)
                }
            }
            
            when("pass a value above maximum...") {
                let aboveMaximum = Constants.flushEventCount.max + 1
                let policy = CountFlushPolicy(flushAt: aboveMaximum)
                
                then("should use default value instead") {
                    XCTAssertEqual(policy.flushAt, defaultValue)
                }
            }
            
            when("pass zero as flush count...") {
                let policy = CountFlushPolicy(flushAt: 0)
                
                then("should use default value instead") {
                    XCTAssertEqual(policy.flushAt, defaultValue)
                }
            }
            
            when("pass negative flush count...") {
                let policy = CountFlushPolicy(flushAt: -5)
                
                then("should use default value instead") {
                    XCTAssertEqual(policy.flushAt, defaultValue)
                }
            }
        }
    }
}

final class FrequencyFlushPolicyTests: XCTestCase {
    
    func test_validFlushFrequency() {
        given("FrequentlyFlushPolicy with 1.5sec flush interval... ") {
            let mills = MockHelper.milliseconds(from: 1.5)
            let policy = FrequencyFlushPolicy(flushIntervalInMillis: UInt64(mills))
            
            when("initiate the shedule...") {
                let client = MockAnalytics()
                policy.scheduleFlush(analytics: client)
                
                RunLoop.current.run(until: Date(timeIntervalSinceNow: MockHelper.seconds(from: mills * 2)))
                then("returns true..") {
                    XCTAssertTrue(client.isFlushed)
                    policy.cancelScheduleFlush()
                }
            }
        }
    }
    
    func test_flushFrequencyWithMinimumValue() {
        given("FrequencyFlushPolicy with minimum valid flush interval...") {
            let minimumInterval = Constants.flushInterval.min
            let policy = FrequencyFlushPolicy(flushIntervalInMillis: minimumInterval)
            
            then("should accept the minimum value") {
                XCTAssertEqual(policy.flushIntervalInMillis, minimumInterval)
            }
        }
    }
    
    func test_invalidFlushFrequency() {
        given("FrequencyFlushPolicy with invalid flush intervals...") {
            let defaultValue = Constants.flushInterval.default
            
            when("prepare the policy with zero interval...") {
                let policy = FrequencyFlushPolicy(flushIntervalInMillis: 0)
                
                then("sets the flush interval to default..") {
                    XCTAssertEqual(policy.flushIntervalInMillis, defaultValue)
                }
            }
            
            when("prepare the policy with below minimum interval...") {
                let belowMinimum = Constants.flushInterval.min - 1
                let policy = FrequencyFlushPolicy(flushIntervalInMillis: belowMinimum)
                
                then("sets the flush interval to default..") {
                    XCTAssertEqual(policy.flushIntervalInMillis, defaultValue)
                }
            }
        }
    }
    
    func test_defaultFlushFrequency() {
        given("FrequencyFlushPolicy with default flush interval... ") {
            let policy = FrequencyFlushPolicy()
            let defaultValue = Constants.flushInterval.default
            
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
