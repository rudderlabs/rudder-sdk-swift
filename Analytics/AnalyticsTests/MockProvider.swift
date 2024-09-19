//
//  MockProvider.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import Foundation
@testable import Analytics

final class MockProvider {
    private init() {}
    
    static let _mockWriteKey = "MoCk_WrItEkEy"
    static var fileIndexKey = Constants.fileIndex + _mockWriteKey
    static var memoryIndexKey = Constants.memoryIndex + _mockWriteKey
    static let userDefaults = UserDefaults.rudder(_mockWriteKey)
    
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
    
    static let keyValueStore: KeyValueStore = KeyValueStore(writeKey: _mockWriteKey)
    
    static let simpleTrackEvent: TrackEvent = {
        let event = TrackEvent(event: "Track_Event", properties: CodableDictionary(["Property_1": "Value1"]), options: CodableDictionary(["Property_1": "Value1"]))
        return event
    }()
}
