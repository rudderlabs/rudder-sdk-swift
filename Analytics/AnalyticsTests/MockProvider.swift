//
//  MockProvider.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Foundation
import Analytics

final class MockProvider {
    private init() {}
    
    private static let _mockWriteKey = "MoCk_WrItEkEy"
    
    static let clientWithDiskStorage: AnalyticsClient = {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .disk)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://www.mock-url.com/", storage: storage)
        
        return AnalyticsClient(configuration: configuration)
    }()
    
    static let clientWithMemoryStorage: AnalyticsClient = {
        let storage = BasicStorage(writeKey: _mockWriteKey, storageMode: .memory)
        let configuration = Configuration(writeKey: _mockWriteKey, dataPlaneUrl: "https://www.mock-url.com/", storage: storage)
        
        return AnalyticsClient(configuration: configuration)
    }()
    
    static let simpleTrackEvent: TrackEvent = {
        let event = TrackEvent(event: "Track_Event", properties: ["Property_1": .string("Value1")], options: ["Property_1": .string("Value1")])
        return event
    }()
}
