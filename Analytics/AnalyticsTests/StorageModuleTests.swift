//
//  StorageModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import XCTest
@testable import Analytics

// MARK: - StorageModuleTests
final class StorageModuleTests: XCTestCase {

    var analytics_disk: AnalyticsClient?
    var analytics_memory: AnalyticsClient?
    var keyValueStore: KeyValueStore?
    
    override func setUpWithError() throws {
        self.analytics_disk = MockProvider.clientWithDiskStorage
        self.analytics_memory = MockProvider.clientWithMemoryStorage
        self.keyValueStore = MockProvider.keyValueStore
    }

    override func tearDownWithError() throws {
        self.analytics_disk = nil
        self.analytics_memory = nil
        self.keyValueStore = nil
    }
}

// MARK: - KeyValueStore
extension StorageModuleTests {
    
    func test_initialization() {
        XCTAssertTrue(self.analytics_disk?.configuration.storage?.eventStorageMode == .disk)
        XCTAssertTrue(self.analytics_memory?.configuration.storage?.eventStorageMode == .memory)
        XCTAssertNotNil(self.keyValueStore)
    }
    
    func test_save_primitive() {
        guard let storage = self.keyValueStore else { XCTFail(); return }
        
        let value1 = 1
        storage.save(value: value1, reference: "IntValue")
        let stored1: Int? = storage.read(reference: "IntValue")
        XCTAssertNotNil(stored1)
        
        let value2 = 2.0
        storage.save(value: value2, reference: "DoubleValue")
        let stored2: Double? = storage.read(reference: "DoubleValue")
        XCTAssertNotNil(stored2)
        
        let value3 = "3"
        storage.save(value: value3, reference: "StringValue")
        let stored3: String? = storage.read(reference: "StringValue")
        XCTAssertNotNil(stored3)
        
        let value4 = true
        storage.save(value: value4, reference: "BoolValue")
        let stored4: Bool? = storage.read(reference: "BoolValue")
        XCTAssertNotNil(stored4)
    }
    
    func test_save_nonPrimitive() {
        guard let storage = self.keyValueStore else { XCTFail(); return }
    
        storage.save(value: MockProvider.simpleTrackEvent, reference: "DataModel")
        let model: TrackEvent? = storage.read(reference: "DataModel")
        XCTAssertNotNil(model)
    }
    
    func test_read_primitive() {
        guard let storage = self.keyValueStore else { XCTFail(); return }
        
        let value1 = 1
        storage.save(value: value1, reference: "IntValue")
        let stored1: Int? = storage.read(reference: "IntValue")
        XCTAssertTrue(value1 == stored1)
        
        let value2 = 2.0
        storage.save(value: value2, reference: "DoubleValue")
        let stored2: Double? = storage.read(reference: "DoubleValue")
        XCTAssertTrue(value2 == stored2)
        
        let value3 = "3"
        storage.save(value: value3, reference: "StringValue")
        let stored3: String? = storage.read(reference: "StringValue")
        XCTAssertTrue(value3 == stored3)
        
        let value4 = true
        storage.save(value: value4, reference: "BoolValue")
        let stored4: Bool? = storage.read(reference: "BoolValue")
        XCTAssertTrue(value4 == stored4)
    }
    
    func test_read_nonPrimitive() {
        guard let storage = self.keyValueStore else { XCTFail(); return }
    
        storage.save(value: MockProvider.simpleTrackEvent, reference: "DataModel")
        guard let model: TrackEvent = storage.read(reference: "DataModel") else { XCTFail(); return }
        XCTAssertTrue(MockProvider.simpleTrackEvent.messageId == model.messageId)
    }
    
    func test_delete() {
        guard let storage = self.keyValueStore else { XCTFail(); return }
        
        let value1 = 1
        storage.save(value: value1, reference: "IntValue")
        storage.delete(reference: "IntValue")
        let stored1: Int? = storage.read(reference: "IntValue")
        XCTAssertNil(stored1)
        
        let value2 = 2.0
        storage.save(value: value2, reference: "DoubleValue")
        storage.delete(reference: "DoubleValue")
        let stored2: Double? = storage.read(reference: "DoubleValue")
        XCTAssertNil(stored2)
        
        let value3 = "3"
        storage.save(value: value3, reference: "StringValue")
        storage.delete(reference: "StringValue")
        let stored3: String? = storage.read(reference: "StringValue")
        XCTAssertNil(stored3)
        
        let value4 = true
        storage.save(value: value4, reference: "BoolValue")
        storage.delete(reference: "BoolValue")
        let stored4: Bool? = storage.read(reference: "BoolValue")
        XCTAssertNil(stored4)
        
        storage.save(value: MockProvider.simpleTrackEvent, reference: "DataModel")
        storage.delete(reference: "DataModel")
        let model: TrackEvent? = storage.read(reference: "DataModel")
        XCTAssertNil(model)
    }
    
}
