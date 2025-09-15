//
//  RudderStackAnalyticsTests.swift
//  RudderStackAnalyticsTests
//
//  Created by Satheesh Kannan on 17/09/24.
//

import XCTest
@testable import RudderStackAnalytics

final class RudderStackAnalyticsTests: XCTestCase {
    var analytics_disk: Analytics?
    var analytics_memory: Analytics?

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
        let configuration = Configuration(writeKey: MockProvider._mockWriteKey, dataPlaneUrl: "https://www.mock-url.com/")
        
        let client = Analytics(configuration: configuration)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let config: String? = client.configuration.storage.read(key: Constants.storageKeys.sourceConfig)
        XCTAssertFalse(((config?.isEmpty) != nil))
    }
}

// MARK: - Disk Store
extension RudderStackAnalyticsTests {
    
    func test_anonymousId() {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        XCTAssert(client.anonymousId?.isEmpty == false)
    }
    
    func test_identify_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.identify(userId: "user_id", traits: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        
        for item in dataItems {
            await client.configuration.storage.remove(batchReference: item.reference)
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
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }
    
    func test_screenEvent_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.screen(screenName: "Screen Event", category: "Main", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover ()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        
        for item in dataItems {
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }
    
    func test_groupEvent_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        client.group(groupId: "group_id", traits: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty)
        for item in dataItems {
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }
    
    func test_reset_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        client.storage.write(value: "test_user_id", key: Constants.storageKeys.userId)
        client.storage.write(value: ["prop": "value"].jsonString, key: Constants.storageKeys.traits)
        
        // Capture the anonymous ID before reset
        let anonymousId = client.anonymousId
        
        client.reset()
        
        XCTAssertFalse(anonymousId == client.anonymousId, "Anonymous ID should be regenerated on reset")
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
        
        // Verify analytics is initially active
        XCTAssertTrue(client.isAnalyticsActive)
        XCTAssertNotNil(client.lifecycleObserver)
        XCTAssertNotNil(client.sessionHandler)
        
        // Shutdown the analytics client
        client.shutdown()
        
        // Give some time for graceful shutdown to complete
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify shutdown state
        XCTAssertFalse(client.isAnalyticsActive, "Analytics should be inactive after shutdown")
        
        // After shutdown, these should be nil due to shutdownHook cleanup
        XCTAssertNil(client.lifecycleObserver, "Lifecycle observer should be nil after shutdown")
        XCTAssertNil(client.sessionHandler, "Session handler should be nil after shutdown")

        // Test that events are not processed after shutdown
        client.track(name: "Track Event", properties: ["prop": "value"])
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.screen(screenName: "Screen Event")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.group(groupId: "Group_id")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.identify(userId: "User_id")
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        client.alias(newId: "Alias_user_id", previousId: nil)
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        // Verify no events were processed after shutdown
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssert(dataItems.isEmpty, "No events should be processed after shutdown")
        
        // Verify user-related properties return nil after shutdown
        XCTAssertNil(client.sessionId, "Session ID should be nil after shutdown")
        XCTAssertNil(client.anonymousId, "Anonymous ID should be nil after shutdown")
        XCTAssertNil(client.userId, "User ID should be nil after shutdown")
        XCTAssertNil(client.traits, "Traits should be nil after shutdown")
    }
    
    func testDeepLinkTracking() async{
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        let testURL = URL(string: "swiftuiapp://testing?id=127&ref=deeplink")!
        let testOptions = ["source": "unitTest"]
        
        client.open(url: testURL, options: testOptions)
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        let dataItems = await client.configuration.storage.read().dataItems
        
        guard let firstItem = dataItems.first else { XCTFail("No data item found"); return }
        let batch = client.storage.eventStorageMode == .memory ? firstItem.batch : (FileManager.contentsOf(file: firstItem.reference) ?? "")
        
        let batchData = batch.toDictionary?["batch"] as? [[String: Any]] ?? []
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
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }
    
    func test_addPlugin_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        let customPlugin = MockPlugin()
        client.add(plugin: customPlugin)
        
        client.track(name: "Original Event")
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty, "Data items should not be empty")
        
        guard let firstItem = dataItems.first else { XCTFail("No data item found"); return }
        let batch = client.storage.eventStorageMode == .memory ? firstItem.batch : (FileManager.contentsOf(file: firstItem.reference) ?? "")
        
        let batchData = batch.toDictionary?["batch"] as? [[String: Any]] ?? []
        guard let lastEvent = batchData.last else { XCTFail("No event found"); return }
        
        XCTAssertTrue(lastEvent["event"] as? String == "New Event Name", "Event name should be modified by the plugin")
        
        for item in dataItems {
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }

    func test_removePlugin_disk() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        let customPlugin = MockPlugin()
        client.add(plugin: customPlugin)
        client.remove(plugin: customPlugin)
        
        client.track(name: "Original Event")
        try? await Task.sleep(nanoseconds: 300_000_000)
        await client.configuration.storage.rollover()
        
        let dataItems = await client.configuration.storage.read().dataItems
        XCTAssertFalse(dataItems.isEmpty, "Data items should not be empty")
        
        guard let firstItem = dataItems.first else { XCTFail("No data item found"); return }
        let batch = client.storage.eventStorageMode == .memory ? firstItem.batch : (FileManager.contentsOf(file: firstItem.reference) ?? "")
        
        let batchData = batch.toDictionary?["batch"] as? [[String: Any]] ?? []
        guard let lastEvent = batchData.last else { XCTFail("No event found"); return }
        
        XCTAssertTrue(lastEvent["event"] as? String == "Original Event", "Event name should remain unchanged after plugin removal")
        
        for item in dataItems {
            await client.configuration.storage.remove(batchReference: item.reference)
        }
    }

    func test_findPlugin_disk() {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        let customPlugin = MockPlugin()
        client.add(plugin: customPlugin)
        
        let foundPlugin = client.find(MockPlugin.self)
        XCTAssertNotNil(foundPlugin, "Should find the added plugin")
        XCTAssertTrue(foundPlugin === customPlugin, "Should return the same plugin instance")
        
        client.remove(plugin: customPlugin)
        
        let removedPlugin = client.find(MockPlugin.self)
        XCTAssertNil(removedPlugin, "Should not find plugin after removal")
    }
}

// MARK: - Identify Reset Behavior Tests
    
extension RudderStackAnalyticsTests {
    
    func test_identify_noResetWhenCurrentUserIdIsEmpty() async {
        given("Analytics client with no previous user identification") {
            guard let client = analytics_disk else { return XCTFail("No disk client") }
            
            let anonymousId = client.anonymousId
            let userId = "first_user"
            
            when("identifying with a user for the first time") {
                client.identify(userId: userId)
                
                then("should not reset (no previous user to reset from)") {
                    XCTAssertEqual(anonymousId, client.anonymousId, "Anonymous ID should not change on first identification")
                    XCTAssertEqual(userId, client.userId, "User ID should be set to first user")
                }
            }
        }
    }
    
    func test_identify_noResetWhenUserIdIsSame() async {
        given("Analytics client with an identified user") {
            guard let client = analytics_disk else { return XCTFail("No disk client") }
            
            let testUserId = "same_user_id"
            client.identify(userId: testUserId)
            
            when("identifying with the same userId") {
                let initialAnonymousId = client.anonymousId
                
                client.identify(userId: testUserId)
                
                then("should not reset") {
                    XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should not change when identifying with same userId")
                    XCTAssertEqual(testUserId, client.userId, "User ID should not change when identifying with same userId")
                }
            }
        }
    }
    
    func test_identify_resetWhenUserIdChanges() async {
        given("Analytics client with an identified user") {
            guard let client = analytics_disk else { return XCTFail("No disk client") }
            
            let initialUserId = "initial_user_id"
            client.identify(userId: initialUserId)
            
            let initialAnonymousId = client.anonymousId
            
            when("identifying with a different userId") {
                let newUserId = "new_user_id"
                client.identify(userId: newUserId)
                
                then("should trigger reset") {
                    XCTAssertNotEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should change when identifying with different userId (reset should occur)")
                    XCTAssertNotNil(client.anonymousId, "New anonymous ID should be generated")
                    XCTAssertEqual(newUserId, client.userId, "User ID should be updated to new user ID")
                }
            }
        }
    }
    
    func test_identify_noResetWhenUserIdIsEmptyOrNotPassed() async {
        given("Analytics client with an identified user") {
            guard let client = analytics_disk else { return XCTFail("No disk client") }
            
            client.identify(userId: "initial_user", traits: ["name": "Initial User"])
            let initialAnonymousId = client.anonymousId
            
            when("identifying with empty userId") {
                client.identify(userId: "", traits: ["name": "Empty User"])
                
                then("should not reset (anonymousId remains the same)") {
                    XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should not change when identifying with empty userId")
                }
            }
            
            when("identifying with only traits") {
                client.identify(traits: ["name": "Anonymous User"])
                
                then("should not reset (anonymousId remains the same)") {
                    XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should not change when identifying with only traits")
                }
            }
        }
    }
}
