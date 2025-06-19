//
//  StorageModuleTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 18/09/24.
//

import XCTest
@testable import RudderStackAnalytics

// MARK: - StorageModuleTests
final class StorageModuleTests: XCTestCase {

    var analytics_disk: AnalyticsClient?
    var analytics_memory: AnalyticsClient?
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        self.analytics_disk = MockProvider.clientWithDiskStorage
        self.analytics_memory = MockProvider.clientWithMemoryStorage
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        self.analytics_disk = nil
        self.analytics_memory = nil
    }
}

// MARK: - KeyValueStore
extension StorageModuleTests {
    
    func test_write_primitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
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
    
    func test_read_primitive() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
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
    
    func test_delete_values() {
        guard let storage = self.analytics_memory?.configuration.storage else { XCTFail("Storage not initialized"); return }
        
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
    }
}

// MARK: - DiskStore
extension StorageModuleTests {
    
    func test_write_event_disk() async {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        let result = await storage.read().dataItems
        XCTAssertFalse(result.isEmpty)
    }
    
    func test_read_event_disk() async {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let files = await storage.read().dataItems
        XCTAssertFalse(files.isEmpty)
    }
    
    func test_remove_event_disk() async {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        let result = await storage.read().dataItems
        
        guard let item = result.first else { XCTFail(); return }
        
        let isRemoved = await storage.remove(eventReference: item.reference)
        XCTAssertTrue(isRemoved)
    }
    
    func test_rollover_event_disk() async {
        guard let storage = self.analytics_disk?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        //clearing all existing files...
        await storage.rollover()
        let files = await storage.read().dataItems
        for file in files {
            await storage.remove(eventReference: file.reference)
        }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let dataItems = await storage.read().dataItems
        XCTAssertTrue(dataItems.count == 1)
    }
}

// MARK: - MemoryStore
extension StorageModuleTests {
    
    func test_write_event_memory() async {
        guard let storage = self.analytics_memory?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.rollover()
        let existingItems = await storage.read().dataItems
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        XCTAssertTrue(resultItems.count > existingItems.count)
    }
    
    func test_read_event_memory() async {
        guard let storage = self.analytics_memory?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        XCTAssertFalse(resultItems.isEmpty)
    }
    
    func test_remove_event_memory() async {
        guard let storage = self.analytics_memory?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.write(event: eventJson)
        await storage.rollover()
        
        let resultItems = await storage.read().dataItems
        for item in resultItems {
            await storage.remove(eventReference: item.reference)
        }
        
        let dataItems = await storage.read().dataItems
        XCTAssertTrue(dataItems.isEmpty)
    }
    
    func test_rollover_event_memory() async {
        guard let storage = self.analytics_memory?.configuration.storage, let eventJson = MockProvider.simpleTrackEvent.jsonString else { XCTFail(); return }
        
        await storage.rollover()
        let resultItems1 = await storage.read().dataItems
        for item in resultItems1 {
            await storage.remove(eventReference: item.reference)
        }

        await storage.write(event: eventJson)
        let resultItems2 = await storage.read().dataItems
        XCTAssertTrue(resultItems2.isEmpty)
        
        await storage.rollover()
        let resultItems3 = await storage.read().dataItems
        XCTAssertFalse(resultItems3.isEmpty)
    }
}
