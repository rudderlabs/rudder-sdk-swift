//
//  MockDestination.swift
//  RudderStackAnalyticsTests
//
//  Created by Vishal Gupta on 16/10/25.
//

import Foundation

/**
 This is a sample destination used inside the mock integration plugins used for testing.
 */
class MockDestination {
    let config: [String: Any]
    
    init(config: [String: Any]) {
        self.config = config
    }
}
