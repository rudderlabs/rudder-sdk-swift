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
    var basicStorage: BasicStorage?
    
    override func setUpWithError() throws {
        self.analytics_disk = MockProvider.clientWithDiskStorage
        self.analytics_memory = MockProvider.clientWithMemoryStorage
        self.keyValueStore = MockProvider.keyValueStore
    }

    override func tearDownWithError() throws {
        self.analytics_disk = nil
        self.analytics_memory = nil
        self.keyValueStore = nil
        self.basicStorage = nil
    }
    
    func test_initialization() {
        XCTAssertTrue(self.analytics_disk?.configuration.storage?.eventStorageMode == .disk)
        XCTAssertTrue(self.analytics_memory?.configuration.storage?.eventStorageMode == .memory)
        XCTAssertNotNil(self.keyValueStore)
    }
}

// MARK: - KeyValueStore
extension StorageModuleTests {
    
    func test_write_primitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail(); return }
        
        let value1 = 1
        storage.write(value: value1, key: "IntValue")
        let stored1: Int? = storage.read(key: "IntValue")
        XCTAssertNotNil(stored1)
        
        let value2 = 2.0
        storage.write(value: value2, key: "DoubleValue")
        let stored2: Double? = storage.read(key: "DoubleValue")
        XCTAssertNotNil(stored2)
        
        let value3 = "3"
        storage.write(value: value3, key: "StringValue")
        let stored3: String? = storage.read(key: "StringValue")
        XCTAssertNotNil(stored3)
        
        let value4 = true
        storage.write(value: value4, key: "BoolValue")
        let stored4: Bool? = storage.read(key: "BoolValue")
        XCTAssertNotNil(stored4)
    }
    
    func test_write_nonPrimitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail(); return }
    
        storage.write(value: MockProvider.simpleTrackEvent, key: "DataModel")
        let model: TrackEvent? = storage.read(key: "DataModel")
        XCTAssertNotNil(model)
    }
    
    func test_read_primitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail(); return }
        
        let value1 = 1
        storage.write(value: value1, key: "IntValue")
        let stored1: Int? = storage.read(key: "IntValue")
        XCTAssertTrue(value1 == stored1)
        
        let value2 = 2.0
        storage.write(value: value2, key: "DoubleValue")
        let stored2: Double? = storage.read(key: "DoubleValue")
        XCTAssertTrue(value2 == stored2)
        
        let value3 = "3"
        storage.write(value: value3, key: "StringValue")
        let stored3: String? = storage.read(key: "StringValue")
        XCTAssertTrue(value3 == stored3)
        
        let value4 = true
        storage.write(value: value4, key: "BoolValue")
        let stored4: Bool? = storage.read(key: "BoolValue")
        XCTAssertTrue(value4 == stored4)
    }
    
    func test_read_nonPrimitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail(); return }
    
        storage.write(value: MockProvider.simpleTrackEvent, key: "DataModel")
        guard let model: TrackEvent = storage.read(key: "DataModel") else { XCTFail(); return }
        XCTAssertTrue(MockProvider.simpleTrackEvent.messageId == model.messageId)
    }
    
    func test_delete_values() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail(); return }
        
        let value1 = 1
        storage.write(value: value1, key: "IntValue")
        storage.remove(key: "IntValue")
        let stored1: Int? = storage.read(key: "IntValue")
        XCTAssertNil(stored1)
        
        let value2 = 2.0
        storage.write(value: value2, key: "DoubleValue")
        storage.remove(key: "DoubleValue")
        let stored2: Double? = storage.read(key: "DoubleValue")
        XCTAssertNil(stored2)
        
        let value3 = "3"
        storage.write(value: value3, key: "StringValue")
        storage.remove(key: "StringValue")
        let stored3: String? = storage.read(key: "StringValue")
        XCTAssertNil(stored3)
        
        let value4 = true
        storage.write(value: value4, key: "BoolValue")
        storage.remove(key: "BoolValue")
        let stored4: Bool? = storage.read(key: "BoolValue")
        XCTAssertNil(stored4)
        
        storage.write(value: MockProvider.simpleTrackEvent, key: "DataModel")
        storage.remove(key: "DataModel")
        let model: TrackEvent? = storage.read(key: "DataModel")
        XCTAssertNil(model)
    }
    
}

// MARK: - DiskStore
extension StorageModuleTests {
    
    func test_write_event_disk() {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.toJSONString else { XCTFail(); return }
        
        storage.write(message: eventJson)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1)) // This will helps to finish the async write operation to finish..
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: MockProvider.currentFileURL.path()))
    }
    
    func test_read_event_disk() {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.toJSONString else { XCTFail(); return }
        
        storage.write(message: eventJson)
        storage.rollover()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        
        guard let files = storage.read().dataFiles else { XCTFail(); return }
        XCTAssertFalse(files.isEmpty)
    }
    
    func test_remove_event_disk() {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.toJSONString else { XCTFail(); return }
        
        storage.write(message: eventJson)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        
        XCTAssertTrue(storage.remove(messageReference: MockProvider.currentFileURL.path()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: MockProvider.currentFileURL.path()))
    }
}
