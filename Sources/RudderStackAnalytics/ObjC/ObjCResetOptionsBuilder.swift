//
//  ObjCResetOptionsBuilder.swift
//  RudderStackAnalytics
//
//  Created by Satheesh Kannan on 09/09/25.
//

import Foundation

/**
 Builder pattern class for constructing ResetOptions instances in Objective-C environments.
 
 Provides a fluent interface for configuring ResetOptions.
 */
@objc(RSSResetOptionsBuilder)
public final class ObjCResetOptionsBuilder: NSObject {
    private var resetEntries = ResetEntries()
    
    /**
     Initializes a new instance of the ObjCResetOptionsBuilder.
     */
    @objc
    public override init() {
        super.init()
    }
    
    /**
     Sets the ResetEntries to be used in the ResetOptions.
     
     - Parameter entries: The ResetEntries instance specifying what to reset.
     - Returns: The builder instance for chaining.
     */
    @objc
    @discardableResult
    public func setResetEntries(_ entries: ResetEntries) -> Self {
        self.resetEntries = entries
        return self
    }
    
    /**
     Builds and returns a ResetOptions instance configured with the specified entries.
     
     - Returns: A ResetOptions instance.
     */
    @objc
    public func build() -> ResetOptions {
        return ResetOptions(entries: resetEntries)
    }
}
