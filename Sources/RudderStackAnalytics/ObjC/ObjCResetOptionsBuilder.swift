//
//  ObjCResetOptionsBuilder.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 09/09/25.
//

import Foundation
/**
 Builder pattern class for constructing ResetOptions instances in Objective-C environments.
 
 Provides a fluent interface for configuring selective user data reset preferences, allowing fine-grained control over which identity components should be cleared during reset operations.
 */
@objc(RSSResetOptionsBuilder)
public final class ObjCResetOptionsBuilder: NSObject {
    private var resetEntries = ResetEntries()
    
    @objc
    public override init() {
        super.init()
    }
    
    @objc
    @discardableResult
    public func setResetEntries(_ entries: ResetEntries) -> Self {
        self.resetEntries = entries
        return self
    }
    
    @objc
    public func build() -> ResetOptions {
        return ResetOptions(entries: resetEntries)
    }
}
