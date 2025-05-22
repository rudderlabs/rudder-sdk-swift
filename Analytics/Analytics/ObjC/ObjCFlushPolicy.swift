//
//  ObjCFlushPolicy.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

@objc(RSFlushPolicy)
public protocol ObjCFlushPolicy {}

@objc(RSStartupFlushPolicy)
public final class ObjcStartupFlushPolicy: NSObject, ObjCFlushPolicy {
    let flushPolicy: StartupFlushPolicy
    
    @objc
    public override init() {
        self.flushPolicy = StartupFlushPolicy()
        super.init()
    }
    
    public init(policy: StartupFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}

@objc(RSCountFlushPolicy)
public final class ObjcCountFlushPolicy: NSObject, ObjCFlushPolicy {
    let flushPolicy: CountFlushPolicy
    
    @objc
    public init(count: Int) {
        self.flushPolicy = CountFlushPolicy(flushCount: count)
        super.init()
    }
    
    @objc
    public convenience override init() {
        self.init(count: Constants.flushEventCount.default)
    }
    
    public init(policy: CountFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}

@objc(RSFrequencyFlushPolicy)
public final class ObjcFrequencyFlushPolicy: NSObject, ObjCFlushPolicy {
    let flushPolicy: FrequencyFlushPolicy
    
    @objc
    public init(flushIntervalInMillis: UInt64) {
        self.flushPolicy = FrequencyFlushPolicy(flushIntervalInMillis: flushIntervalInMillis)
        super.init()
    }
    
    @objc
    public convenience override init() {
        self.init(flushIntervalInMillis: Constants.flushInterval.default)
    }
    
    public init(policy: FrequencyFlushPolicy) {
        self.flushPolicy = policy
        super.init()
    }
}
