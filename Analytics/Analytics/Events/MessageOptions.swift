//
//  MessageOptions.swift
//  Analytics
//
//  Created by Satheesh Kannan on 12/11/24.
//

import Foundation

// MARK: - RudderOptionType
/**
 This is a base protocol for managing Rudder options.
 */
protocol RudderOptionType {
    var integrations: [String: Bool]? { get set }
    var customContext: [String: Any]? { get }
    
    func addIntegration(_ integration: String, isEnabled: Bool) -> Self
    func addCustomContext(_ context: Any, key: String) -> Self
}

extension RudderOptionType {
    func addIntegration(_ integrations: inout [String: Bool]?, values: [String: Bool]) {
        if integrations == nil { integrations = Constants.defaultIntegration }
        integrations?.merge(values, uniquingKeysWith: { $1 })
    }
    
    func addCustomContext(_ context: inout [String: Any]?, values: [String: Any]) {
        if context == nil { context = [:] }
        context?.merge(values, uniquingKeysWith: { $1 })
    }
}

// MARK: - RudderOptions
/**
 This class implements the `RudderOptionType` protocol, which is used to add options to message events.
 */
public class RudderOptions: RudderOptionType {
    internal(set) public var integrations: [String: Bool]?
    private(set) public var customContext: [String: Any]?
    
    public init() {
        self.integrations = Constants.defaultIntegration
    }
    
    @discardableResult
    public func addIntegration(_ integration: String, isEnabled: Bool) -> Self {
        self.addIntegration(&self.integrations, values: [integration: isEnabled])
        return self
    }
    
    @discardableResult
    public func addCustomContext(_ context:Any, key: String) -> Self {
        self.addCustomContext(&self.customContext, values: [key: context])
        return self
    }
}
