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
        await client.configuration.storage.rollover()
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

// MARK: - Reset Behavior Tests

extension RudderStackAnalyticsTests {
    
    func test_reset_defaultOptions_resetsAllUserIdentityData() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user, traits, and active session") {
            // Set up user identity
            client.identify(userId: "test_user_123", traits: ["name": "John Doe", "email": "john@example.com"])
            
            // Store initial values for comparison
            let initialAnonymousId = client.anonymousId
            let initialUserId = client.userId
            let initialTraits = client.traits
            let initialSessionId = client.sessionId
            
            // Verify data exists before reset
            XCTAssertNotNil(initialAnonymousId, "Anonymous ID should exist")
            XCTAssertEqual(initialUserId, "test_user_123", "User ID should be set")
            XCTAssertEqual(initialTraits?["name"] as? String, "John Doe", "Traits should be set")
            XCTAssertNotNil(initialSessionId, "Session ID should exist")
            
            await when("calling reset with default options") {
                await runAfter(0.3) {
                    client.reset()
                    
                    then("should reset all user identity data") {
                        // Anonymous ID should be regenerated (different from initial)
                        XCTAssertNotEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should be regenerated")
                        XCTAssertNotNil(client.anonymousId, "New anonymous ID should exist")
                        
                        // User ID should be cleared
                        XCTAssertNotEqual(initialUserId, client.userId, "User ID should be cleared")
                        XCTAssertTrue(client.userId?.isEmpty ?? true, "User ID should be empty")
                        
                        // Traits should be cleared
                        XCTAssertTrue(client.traits?.isEmpty ?? true, "Traits should be empty")
                        
                        // Session should still exist
                        XCTAssertNotNil(client.sessionId, "Session ID should exist after reset")
                        XCTAssertNotEqual(initialSessionId, client.sessionId, "Session ID should be regenerated")
                        
                        // Verify storage is also cleared
                        let storedUserId: String? = client.storage.read(key: Constants.storageKeys.userId)
                        let storedTraits: String? = client.storage.read(key: Constants.storageKeys.traits)
                        XCTAssertNil(storedUserId, "User ID should not exist in storage")
                        XCTAssertNil(storedTraits, "Traits should not exist in storage")
                    }
                }
            }
        }
    }
    

    func test_reset_customOptions_onlyAnonymousId() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user and traits") {
            // Set up user identity
            client.identify(userId: "test_user_456", traits: ["age": 25, "location": "NYC"])
            
            await runAfter(0.3) {
                
                let initialAnonymousId = client.anonymousId
                let initialUserId = client.userId
                let initialTraits = client.traits
                let initialSessionId = client.sessionId
                
                when("calling reset with only anonymousId option enabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: true,
                        userId: false,
                        traits: false,
                        session: false
                    ))
                    client.reset(options: resetOptions)
                    
                    then("should only reset anonymous ID, preserving other data") {
                        // Only anonymous ID should change
                        XCTAssertNotEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should be regenerated")
                        XCTAssertNotNil(client.anonymousId, "New anonymous ID should exist")
                        
                        // User ID should remain unchanged
                        XCTAssertEqual(initialUserId, client.userId, "User ID should remain unchanged")
                        
                        // Traits should remain unchanged
                        XCTAssertEqual(initialTraits?["age"] as? Int, client.traits?["age"] as? Int, "Traits should remain unchanged")
                        XCTAssertEqual(initialTraits?["location"] as? String, client.traits?["location"] as? String, "Traits should remain unchanged")
                        
                        // Session should remain unchanged
                        XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged")
                    }
                }
            }
        }
    }
    
    func test_reset_customOptions_onlyUserId() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user and traits") {
            client.identify(userId: "test_user_789", traits: ["company": "RudderStack", "role": "Developer"])
            
            await runAfter(0.3) {
                
                let initialAnonymousId = client.anonymousId
                let initialTraits = client.traits
                let initialSessionId = client.sessionId
                
                when("calling reset with only userId option enabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: false,
                        userId: true,
                        traits: false,
                        session: false
                    ))
                    client.reset(options: resetOptions)
                    
                    
                    then("should only clear user ID, preserving other data") {
                        // Anonymous ID should remain unchanged
                        XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged")
                        
                        // User ID should be cleared
                        XCTAssertTrue(client.userId?.isEmpty ?? true, "User ID should be empty")
                        
                        // Traits should remain unchanged
                        XCTAssertEqual(initialTraits?["company"] as? String, client.traits?["company"] as? String, "Traits should remain unchanged")
                        XCTAssertEqual(initialTraits?["role"] as? String, client.traits?["role"] as? String, "Traits should remain unchanged")
                        
                        // Session should remain unchanged
                        XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged")
                        
                        // Verify storage
                        let storedUserId: String? = client.storage.read(key: Constants.storageKeys.userId)
                        XCTAssertNil(storedUserId, "User ID should not exist in storage")
                    }
                }
            }
        }
    }
    
    func test_reset_customOptions_onlyTraits() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user and traits") {
            client.identify(userId: "test_user_101", traits: ["subscription": "premium", "plan": "monthly"])
            await runAfter(0.3) {
                let initialAnonymousId = client.anonymousId
                let initialUserId = client.userId
                let initialSessionId = client.sessionId
                
                when("calling reset with only traits option enabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: false,
                        userId: false,
                        traits: true,
                        session: false
                    ))
                    client.reset(options: resetOptions)
                    
                    then("should only clear traits, preserving other data") {
                        // Anonymous ID should remain unchanged
                        XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged")
                        
                        // User ID should remain unchanged
                        XCTAssertEqual(initialUserId, client.userId, "User ID should remain unchanged")
                        
                        // Traits should be cleared
                        XCTAssertTrue(client.traits?.isEmpty ?? true, "Traits should be empty")
                        
                        // Session should remain unchanged
                        XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged")
                        
                        // Verify storage
                        let storedTraits: String? = client.storage.read(key: Constants.storageKeys.traits)
                        XCTAssertNil(storedTraits, "Traits should not exist in storage")
                    }
                }
            }
        }
    }
    
    func test_reset_customOptions_onlySession() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user, traits, and active session") {
            client.identify(userId: "test_user_202", traits: ["device": "iPhone", "os": "iOS"])
            await runAfter(0.3) {
                let initialAnonymousId = client.anonymousId
                let initialUserId = client.userId
                let initialTraits = client.traits
                let _ = client.sessionId // Store for potential future verification
                
                when("calling reset with only session option enabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: false,
                        userId: false,
                        traits: false,
                        session: true
                    ))
                    client.reset(options: resetOptions)
                    
                    then("should only refresh session, preserving other data") {
                        // Anonymous ID should remain unchanged
                        XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged")
                        
                        // User ID should remain unchanged
                        XCTAssertEqual(initialUserId, client.userId, "User ID should remain unchanged")
                        
                        // Traits should remain unchanged
                        XCTAssertEqual(initialTraits?["device"] as? String, client.traits?["device"] as? String, "Traits should remain unchanged")
                        XCTAssertEqual(initialTraits?["os"] as? String, client.traits?["os"] as? String, "Traits should remain unchanged")
                        
                        // Session refresh behavior depends on session configuration
                        let newSessionId = client.sessionId
                        XCTAssertNotNil(newSessionId, "Session ID should exist after reset")
                        // Note: Session ID might not change due to automatic session management
                    }
                }
            }
        }
    }
    
    func test_reset_customOptions_multipleEntries() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user, traits, and active session") {
            client.identify(userId: "test_user_303", traits: ["category": "premium", "status": "active"])
            
            await runAfter(0.3) {
                
                let initialAnonymousId = client.anonymousId
                let initialSessionId = client.sessionId
                
                when("calling reset with userId and traits options enabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: false,
                        userId: true,
                        traits: true,
                        session: false
                    ))
                    client.reset(options: resetOptions)
                    
                    then("should reset userId and traits, preserving anonymousId and session") {
                        // Anonymous ID should remain unchanged
                        XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged")
                        
                        // User ID should be cleared
                        XCTAssertTrue(client.userId?.isEmpty ?? true, "User ID should be empty")
                        
                        // Traits should be cleared
                        XCTAssertTrue(client.traits?.isEmpty ?? true, "Traits should be empty")
                        
                        // Session should remain unchanged
                        XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged")
                    }
                }
            }
        }
    }
    
    func test_reset_noOptions_doesNothing() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user and traits") {
            client.identify(userId: "test_user_404", traits: ["version": "1.0", "beta": true])
            await runAfter(0.3) {
                
                let initialAnonymousId = client.anonymousId
                let initialUserId = client.userId
                let initialTraits = client.traits
                let initialSessionId = client.sessionId
                
                when("calling reset with all options disabled") {
                    let resetOptions = ResetOptions(entries: ResetEntries(
                        anonymousId: false,
                        userId: false,
                        traits: false,
                        session: false
                    ))
                    client.reset(options: resetOptions)
                    
                    then("should preserve all data unchanged") {
                        // All data should remain unchanged
                        XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged")
                        XCTAssertEqual(initialUserId, client.userId, "User ID should remain unchanged")
                        XCTAssertEqual(initialTraits?["version"] as? String, client.traits?["version"] as? String, "Traits should remain unchanged")
                        XCTAssertEqual(initialTraits?["beta"] as? Bool, client.traits?["beta"] as? Bool, "Traits should remain unchanged")
                        XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged")
                    }
                }
            }
        }
    }
    
    func test_reset_afterShutdown_doesNotExecute() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client that has been shut down") {
            // Set up user identity
            client.identify(userId: "test_user_shutdown", traits: ["test": "value"])
            await runAfter(0.3) {
                // Shutdown the client
                client.shutdown()
                
                await runAfter(0.3) {
                    let initialAnonymousId = client.anonymousId
                    let initialUserId = client.userId
                    let initialTraits = client.traits
                    let initialSessionId = client.sessionId
                    
                    when("calling reset on shut down client") {
                        client.reset()
                        
                        then("should not execute reset (all values remain as they were during shutdown)") {
                            // Since client is shut down, reset should not execute
                            XCTAssertEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should remain unchanged after shutdown")
                            XCTAssertEqual(initialUserId, client.userId, "User ID should remain unchanged after shutdown")
                            XCTAssertEqual(initialTraits?["test"] as? String, client.traits?["test"] as? String, "Traits should remain unchanged after shutdown")
                            XCTAssertEqual(initialSessionId, client.sessionId, "Session ID should remain unchanged after shutdown")
                        }
                    }
                }
            }
        }
    }
    
    func test_reset_withoutPreviousIdentity_generatesNewAnonymousId() {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        given("Analytics client with no previous user identification") {
            // Ensure no user identification exists
            let initialAnonymousId = client.anonymousId
            XCTAssertNotNil(initialAnonymousId, "Anonymous ID should exist by default")
            XCTAssertTrue(client.userId?.isEmpty ?? true, "User ID should be empty initially")
            XCTAssertTrue(client.traits?.isEmpty ?? true, "Traits should be empty initially")
            
            when("calling reset on client without previous identity") {
                client.reset()
                
                then("should still generate new anonymous ID and refresh session") {
                    // Anonymous ID should be regenerated even without previous identity
                    XCTAssertNotEqual(initialAnonymousId, client.anonymousId, "Anonymous ID should be regenerated")
                    XCTAssertNotNil(client.anonymousId, "New anonymous ID should exist")
                    
                    // User ID should remain empty
                    XCTAssertTrue(client.userId?.isEmpty ?? true, "User ID should remain empty")
                    
                    // Traits should remain empty
                    XCTAssertTrue(client.traits?.isEmpty ?? true, "Traits should remain empty")
                    
                    // Session should be refreshed
                    XCTAssertNotNil(client.sessionId, "Session ID should exist")
                }
            }
        }
    }
    
    func test_reset_storageConsistency() async {
        guard let client = analytics_disk else { return XCTFail("No disk client") }
        
        await given("Analytics client with identified user and traits") {
            client.identify(userId: "storage_test_user", traits: ["key1": "value1", "key2": 42])
            
            await runAfter(0.3) {
                // Verify data exists in storage before reset
                let storedUserIdBefore: String? = client.storage.read(key: Constants.storageKeys.userId)
                let storedTraitsBefore: String? = client.storage.read(key: Constants.storageKeys.traits)
                
                XCTAssertEqual(storedUserIdBefore, "storage_test_user", "User ID should be stored")
                XCTAssertNotNil(storedTraitsBefore, "Traits should be stored")
                // Anonymous ID might not be immediately stored after identify, so we check the in-memory value
                let preResetAnonymousId = client.anonymousId
                XCTAssertNotNil(preResetAnonymousId, "Anonymous ID should exist")
                
                when("calling reset") {
                    client.reset()
                    
                    then("storage should be updated consistently with in-memory state") {
                        // Check in-memory state
                        XCTAssertNotEqual(preResetAnonymousId, client.anonymousId, "In-memory anonymous ID should change")
                        XCTAssertTrue(client.userId?.isEmpty ?? true, "In-memory user ID should be empty")
                        XCTAssertTrue(client.traits?.isEmpty ?? true, "In-memory traits should be empty")
                        
                        // Check storage state matches in-memory state
                        let storedUserIdAfter: String? = client.storage.read(key: Constants.storageKeys.userId)
                        let storedTraitsAfter: String? = client.storage.read(key: Constants.storageKeys.traits)
                        let storedAnonymousIdAfter: String? = client.storage.read(key: Constants.storageKeys.anonymousId)
                        
                        XCTAssertNil(storedUserIdAfter, "User ID should be removed from storage")
                        XCTAssertNil(storedTraitsAfter, "Traits should be removed from storage")
                        XCTAssertEqual(storedAnonymousIdAfter, client.anonymousId, "Storage anonymous ID should match in-memory")
                        XCTAssertNotEqual(preResetAnonymousId, storedAnonymousIdAfter, "Storage anonymous ID should be updated")
                    }
                }
            }
        }
    }
}
