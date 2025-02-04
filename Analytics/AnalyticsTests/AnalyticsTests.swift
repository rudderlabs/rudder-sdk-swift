//
//  AnalyticsTests.swift
//  AnalyticsTests
//
//  Created by Satheesh Kannan on 17/09/24.
//

import XCTest
@testable import Analytics

final class AnalyticsTests: XCTestCase {
    var analytics_disk: AnalyticsClient?
    var analytics_memory: AnalyticsClient?

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        self.analytics_disk = MockProvider.clientWithDiskStorage
        self.analytics_memory = MockProvider.clientWithMemoryStorage
        self.analytics_disk?.configuration.storage.remove(key: StorageKeys.anonymousId)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        self.analytics_disk = nil
        self.analytics_memory = nil
    }
    
    func test_sourceConfiguration() {
        let storage = BasicStorage(writeKey: MockProvider._mockWriteKey, storageMode: .disk)
        let configuration = Configuration(writeKey: MockProvider._mockWriteKey, dataPlaneUrl: "https://www.mock-url.com/", storage: storage)
        
        let client = AnalyticsClient(configuration: configuration)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let config: String? = client.configuration.storage.read(key: StorageKeys.sourceConfig)
        XCTAssertFalse(((config?.isEmpty) != nil))
    }
}
// MARK: - Disk Store
extension AnalyticsTests {
    
    func test_anonymousId() {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        XCTAssertFalse(client.anonymousId.isEmpty)
        
        let testId = "testId"
        client.anonymousId = testId
        XCTAssertEqual(client.anonymousId, testId)
    }
    
    func test_identify_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.identify(userId: "user_id", traits: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        
        for item in dataItems {
            await client.configuration.storage.remove(messageReference: item.reference)
        }
    }
    
    func test_trackEvent_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.track(name: "Track Event", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        
        for item in dataItems {
            await client.configuration.storage.remove(messageReference: item.reference)
        }
    }
    
    func test_screenEvent_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.screen(name: "Screen Event", category: "Main", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover ()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        
        for item in dataItems {
            await client.configuration.storage.remove(messageReference: item.reference)
        }
    }
    
    func test_groupEvent_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.group(id: "group_id", traits: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        for item in dataItems {
            await client.configuration.storage.remove(messageReference: item.reference)
        }
    }
    
    func test_flushEvents_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.track(name: "Track Event", properties: ["prop": "value"])
        client.flush()
        try? await Task.sleep(nanoseconds: 300_000_000)
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty) //Should be false.. Since no proper dataplane configured...
    }
}
