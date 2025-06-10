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
        self.analytics_disk?.configuration.storage.remove(key: Constants.storageKeys.anonymousId)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        self.analytics_disk = nil
        self.analytics_memory = nil
    }
    
    func test_sourceConfiguration() {
        let configuration = Configuration(writeKey: MockProvider._mockWriteKey, dataPlaneUrl: "https://www.mock-url.com/", storageMode: .disk)
        
        let client = AnalyticsClient(configuration: configuration)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let config: String? = client.configuration.storage.read(key: Constants.storageKeys.sourceConfig)
        XCTAssertFalse(((config?.isEmpty) != nil))
    }
}
// MARK: - Disk Store
extension AnalyticsTests {
    
    func test_anonymousId() {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        XCTAssert(client.anonymousId?.isEmpty == false)
        
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
            await client.configuration.storage.remove(eventReference: item.reference)
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
            await client.configuration.storage.remove(eventReference: item.reference)
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
            await client.configuration.storage.remove(eventReference: item.reference)
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
            await client.configuration.storage.remove(eventReference: item.reference)
        }
    }
    
    func test_reset_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        client.storage.write(value: "test_user_id", key: Constants.storageKeys.userId)
        client.storage.write(value: ["prop": "value"].jsonString, key: Constants.storageKeys.traits)
        
        // Capture the anonymous ID before reset - it should be preserved
        let anonymousId = client.anonymousId
        
        client.reset()
        
        XCTAssertFalse(anonymousId == client.anonymousId)
        let userId: String? = client.storage.read(key: Constants.storageKeys.userId)
        XCTAssertTrue(userId == nil)
        let trits: String? = client.storage.read(key: Constants.storageKeys.traits)
        XCTAssertTrue(trits == nil)
    }
    
    func test_flushEvents_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.track(name: "Track Event", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        client.flush()
        try? await Task.sleep(nanoseconds: 300_000_000)
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty) //Should be false.. Since no proper dataplane configured...
    }
    
    func test_shutdown() async {
        guard let client = analytics_disk else { XCTFail("No disk client"); return }
        client.shutdown()

        XCTAssertFalse(client.isAnalyticsActive)
        XCTAssertNil(client.lifecycleObserver)
        XCTAssertNil(client.sessionHandler)

        client.track(name: "Track Event", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.screen(name: "Screen Event")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.group(id: "Group_id")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.identify(userId: "User_id")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.alias(newId: "Alias_user_id", previousId: nil)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssert(dataItems.isEmpty)
        
        XCTAssertNil(client.sessionId)
        XCTAssertNil(client.anonymousId)
        XCTAssertNil(client.userId)
        XCTAssertNil(client.traits)
    }
    
    func testDeepLinkTracking() async{
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        let testURL = URL(string: "analyticsapp://testing?id=127&ref=deeplink")!
        let testOptions = ["source": "unitTest"]
        
        client.openURL(testURL, options: testOptions)
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        let batchData = dataItems.first?.batch.toDictionary?["batch"] as? [[String: Any]] ?? []
        guard let lastEvent = batchData.last else { XCTFail("No event found"); return }
        
        XCTAssertEqual(lastEvent["event"] as? String, "Deep Link Opened")

        if let properties = lastEvent["properties"] as? [String: Any] {
            XCTAssertEqual(properties["url"] as? String, testURL.absoluteString)
            XCTAssertEqual(properties["id"] as? String, "127")
            XCTAssertEqual(properties["ref"] as? String, "deeplink")
            XCTAssertEqual(properties["source"] as? String, "unitTest")
        } else {
            XCTFail("Event properties not found")
        }
        
        for item in dataItems {
            await client.configuration.storage.remove(eventReference: item.reference)
        }
    }
}
