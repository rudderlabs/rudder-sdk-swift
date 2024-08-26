//
//  AnalyticsClient.swift
//  Analytics
//
//  Created by Satheesh Kannan on 14/08/24.
//

import Foundation

@objcMembers
public class Analytics {
    public var configuration: Configuration
    
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
}

public struct Constants {
    public static let logTag = "Rudder-Analytics"
    public static let defaultLogLevel = LogLevel.none
    
    private init() {}
}
