//
//  ObjCAnalytics.swift
//  Analytics
//
//  Created by Satheesh Kannan on 22/05/25.
//

import Foundation

@objc(RSAnalytics)
public class ObjCAnalytics: NSObject {
    
    let analytics: AnalyticsClient
    
    @objc
    public init(configuration: ObjCConfiguration) {
        self.analytics = AnalyticsClient(configuration: configuration.configuration)
    }
    
}
